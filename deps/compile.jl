using Glob.glob

const FORTRAN_FUNCTIONS =
    [:dnrm2, :dasum, :ddot, :idamax, :dgemm, :dgemv, :dger,
     :dtrsm, :dtrmv, :dpotrf, :dpotrs, :dpotri, :dtrtri]
 
function find_obj(makefile_path=Makefile)
     makefile = readstring(makefile_path)
    m = match(r"libsdp\.a\:(.+)", makefile)
    m != nothing || error("Could not find `libsdp.a` target in '$makefile_path'")
    objs = matchall(r"\w+\.o", m.captures[1])
    objs = String[splitext(o)[1] for o in [objs; basename(patchf)]]
end

function patch_int(; verbose::Bool = false)
    let patchsrc = "$srcdir/$(basename(patchf))"
        isfile(patchsrc) || cp(patchf, patchsrc)
    end
    if JULIA_LAPACK
        info("Patching int --> integer")
        cfiles = [glob("*.c", srcdir); [joinpath(srcdir, "..", "include", "$d.h")
                                        for d in ["declarations",
                                                  "blockmat",
                                                  "parameters"]]]
        for cfile in cfiles
            if verbose; println(cfile); end
            content = readstring(cfile)
            for (re,subst) in
                [(r"int ([^(]+);", s"integer \1;"),
                 (r"int ", s"integer "),
                 (r"int \*", s"integer *"),
                 (r"integer mycompare", s"int mycompare"),
                 (r"\(int\)", s"(integer)"),
                 (r"%d", s"%ld"),
                 (r"%2d", s"%2ld"),
                 (r" int ", s" integer ")]
                content = replace(content, re, subst)
            end
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
            for f in FORTRAN_FUNCTIONS
                let ext=string(BLAS.@blasfunc "")
                    push!(cflags, "-D$(f)_=$(f)_$ext")
                end
            end
            info(cflags)
        end
    else
        libs = ["-l$l" for l in ["blas", "lapack"]]
        @static if is_windows() unshift!(libs, "-L$libdir") end
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
