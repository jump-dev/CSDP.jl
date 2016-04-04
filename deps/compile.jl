function find_obj(makefile_path=Makefile)
    # patch: symlink debugging source
    patchsrc = "$srcdir/$(basename(patchf))"
    isfile(patchsrc) || symlink(patchf, patchsrc)
    makefile = readall(makefile_path)
    m = match(r"libsdp\.a\:(.+)", makefile)
    m != nothing || error("Could not find `libsdp.a` target in '$makefile_path'")
    objs = matchall(r"\w+\.o", m.captures[1])
    objs = UTF8String[splitext(o)[1] for o in [objs; basename(patchf)]]
end


function compile_objs()
    for o in find_obj()
        info("CC $o.c")
        run(`gcc -fPIC $cflags -o $builddir/$o.o -c $srcdir/$o.c`)
    end
    objs = ["$builddir/$o.o" for o in find_obj()]
    libs = ["-l$l" for l in ["blas", "lapack"]]
    cmd = `gcc -shared -o $dlpath $objs $libs`
    try
        run(cmd)
        info("LINK --> $dlpath")
    catch
        println(cmd)
    end
end
