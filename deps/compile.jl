using Glob.glob

function find_obj(makefile_path=Makefile)
    # patch: symlink debugging source
    patchsrc = "$srcdir/$(basename(patchf))"
    mylink = @static is_windows() ? cp : symlink
    isfile(patchsrc) || mylink(patchf, patchsrc)
    makefile = readstring(makefile_path)
    m = match(r"libsdp\.a\:(.+)", makefile)
    m != nothing || error("Could not find `libsdp.a` target in '$makefile_path'")
    objs = matchall(r"\w+\.o", m.captures[1])
    objs = UTF8String[splitext(o)[1] for o in [objs; basename(patchf)]]
end

function patch_int()
    if JULIA_LAPACK
        info("Patching INT --> integer")
        cfiles = [glob("*.c", srcdir); joinpath(srcdir, "..", "include", "declarations.h")]
        for cfile in cfiles
            content = readstring(cfile)
            content = replace(content, r"int ([^(]+);", s"integer \1;")
            content = replace(content, r"%d", s"%ld")
            open(cfile, "w") do io
                print(io, content)
            end
        end
    end
end


function compile_objs(JULIA_LAPACK=JULIA_LAPACK)
    if JULIA_LAPACK
        lapack = Libdl.dlpath(LinAlg.LAPACK.liblapack)
        lflag = replace(splitext(basename(lapack))[1], r"^lib", "")
        libs = ["-L$(dirname(lapack))", "-l$lflag"]
        info(libs)
        if endswith(LinAlg.LAPACK.liblapack, "64_")
            push!(cflags, "-march=x86-64", "-m64", "-Dinteger=long")
            for f in [:dnrm2, :dasum, :ddot, :idamax, :dgemm, :dgemv, :dger,
                      :dtrsm, :dtrmv, :dpotrf, :dpotrs, :dpotri, :dtrtri]
                push!(cflags, "-D$(f)_=$(f)_64_")
            end
            info(cflags)
        end
    else
        libs = ["-l$l" for l in ["blas", "lapack"]]
        @static if is_windows() unshift!(libs, "-L$libdir") end
        # libs = @static is_windows() ? ["-L$libdir", "-latlas"] : ["-l$l" for l in ["blas", "lapack"]]
        # @static if is_windows()
        #     unshift!(libs, "-march=x86-64")
        #     push!(cflags, "-march=x86-64")
        # end
    end


    for o in find_obj()
        info("CC $o.c")
        @static if is_unix()  push!(cflags, "-fPIC") end
        run(`$CC $cflags -o $builddir/$o.o -c $srcdir/$o.c`)
    end
    objs = ["$builddir/$o.o" for o in find_obj()]
    cmd = `gcc -shared -o $dlpath $objs $libs`
    try
        run(cmd)
        info("LINK --> $dlpath")
    catch
        println(cmd)
    end
end
