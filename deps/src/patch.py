# Starting point https://github.com/llvm-mirror/clang/blob/master/bindings/python/examples/cindex/cindex-dump.py

from clang.cindex import Index
from  clang.cindex import CursorKind as C
import os

HEADER = "Csdp-6.1.1/include/declarations.h"

idx = Index.create()
tu = idx.parse(HEADER)
children = list(tu.cursor.get_children())

lapack = [c.spelling for c in children
          if c.kind == C.FUNCTION_DECL and c.spelling.endswith("_")]


def cblas_header(cblas_h = "cblas.h"):
    """Return the cblas header as string (is downloaded if not found)"""
    cblas_url = "https://raw.githubusercontent.com/xianyi/OpenBLAS/master/cblas.h"
    if not os.path.exists(cblas_h):
        r = requests.get(cblas_url)
        assert r.status_code == 200
        with open(cblas_h, "w") as io:
            io.write(r.content)
        return r.content
    else:
        return open(cblas_h).read()


        
