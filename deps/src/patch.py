#!/usr/bin/env python
# Starting point https://github.com/llvm-mirror/clang/blob/master/bindings/python/examples/cindex/cindex-dump.py
#
# Needs clang module to be installed.
#

from __future__ import print_function
import os
import re
import requests
import sys
import shutil

try:
    from clang.cindex import Index
    from clang.cindex import CursorKind as C
except ImportError:
    print("You need to install `clang`. In Python e.g.\n$ pip install 'libclang-py3'",
          file=sys.stderr)
    exit(1)


HEADER    = "Csdp-6.1.1/include/declarations.h"
LAPACK_RE = "([di].+)_"

def function_decl(header = HEADER):
    """Return list of cursors to all function declarations in header"""
    idx = Index.create()
    tu = idx.parse(header)
    return [c for c in tu.cursor.get_children()
            if c.kind == C.FUNCTION_DECL]


def cblas_header(cblas_h = "cblas.h"):
    """Return the cblas header as string (is downloaded if not found)"""
    cblas_url = "https://raw.githubusercontent.com/xianyi/OpenBLAS/master/cblas.h"
    if not os.path.exists(cblas_h):
        r = requests.get(cblas_url)
        assert r.status_code == 200
        with open(cblas_h, "wb") as io:
            io.write(r.content)
        return r.content
    else:
        return open(cblas_h).read()

def clapack_header(clapack_h = "clapack.h"):
    """Return the clapack header as string (is downloaded if not found)"""
    clapack_url = "http://www.netlib.org/clapack/clapack.h"
    if not os.path.exists(clapack_h):
        r = requests.get(clapack_url)
        assert r.status_code == 200
        with open(clapack_h, "wb") as io:
            io.write(r.content)
        return r.content
    else:
        return open(clapack_h).read()


def substr(s, c):
    return s[c.extent.start.offset:c.extent.end.offset+1]


def patch(origin_header, out = sys.stdout):
    cursors = function_decl(origin_header)
    wrong = {c.spelling : c for c in cursors
               if re.match(LAPACK_RE, c.spelling)}
    fnames = [c.spelling for c in cursors
              if re.match(LAPACK_RE, c.spelling)]

    clapack = clapack_header()
    lapack_fs = function_decl("clapack.h")
    correct = {c.spelling : c for c in lapack_fs if c.spelling in fnames}

    header = open(origin_header).read()
    pos = 0
    for fn in fnames:
        c = correct[fn]
        w = wrong[fn]
        a, b = w.extent.start.offset, w.extent.end.offset
        repl = substr(clapack, c)
        print(header[pos:a], file=out)
        print(repl, file=out)
        pos = b+1
    print(header[pos:], file=out)


if __name__ == "__main__":
    header_backup = HEADER + ".bak.h"
    header_new    = HEADER + ".new"
    if not os.path.exists(header_backup):
        shutil.copy(HEADER, header_backup)
        print("Creating backup " + header_backup)
    with open(header_new, "w") as io:
        patch(header_backup, io)
    shutil.move(header_new, HEADER)
