using Glob.glob

function find_obj(makefile_path=Makefile)
    # patch: symlink debugging source
    patchsrc = "$srcdir/$(basename(patchf))"
    mylink = @windows? cp : symlink
    isfile(patchsrc) || mylink(patchf, patchsrc)
    makefile = readall(makefile_path)
    m = match(r"libsdp\.a\:(.+)", makefile)
    m != nothing || error("Could not find `libsdp.a` target in '$makefile_path'")
    objs = matchall(r"\w+\.o", m.captures[1])
    objs = UTF8String[splitext(o)[1] for o in [objs; basename(patchf)]]
end

function patch_int()
    if JULIA_LAPACK
        info("Patching INT --> LONG INT")
        cfiles = [glob("*.c", srcdir); joinpath(srcdir, "..", "include", "declarations.h")]
        for cfile in cfiles
            content = readall(cfile)
            content = replace(content, r"int ([^(]+);", s"long int \1;")
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
            push!(cflags, "-march=x86-64", "-m64")
            for f in [:dnrm2, :dasum, :ddot, :idamax, :dgemm, :dgemv, :dger,
                      :dtrsm, :dtrmv, :dpotrf, :dpotrs, :dpotri, :dtrtri]
                push!(cflags, "-D$(f)_=$(f)_64_")
            end
            # info(cflags)
        end
    else
        libs = ["-l$l" for l in ["blas", "lapack"]]
        @windows_only begin
            unshift!(libs, "-L$libdir", "-march=x86-64", "-m32")
            push!(cflags, "-march=x86-64", "-m32")
        end
    end

    for o in find_obj()
        info("CC $o.c")
        run(`$CC -fPIC $cflags -o $builddir/$o.o -c $srcdir/$o.c`)
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
