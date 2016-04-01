using BinDeps

@BinDeps.setup

const version = "6.1.1"
libname = "libcsdp.$(Libdl.dlext)"

blas = library_dependency("libblas")
lapack = library_dependency("liblapack")
csdp = library_dependency("csdp", aliases=[libname], depends=[blas, lapack])

srcdir = joinpath(BinDeps.depsdir(csdp), "src", "Csdp-$version", "lib")
prefix = joinpath(BinDeps.depsdir(csdp), "usr")
libdir = joinpath(prefix, "lib/")
builddir = joinpath(BinDeps.depsdir(csdp), "build")
dlpath = joinpath(libdir, libname)
cflags = ["-I$srcdir/../include",  "-DNOSHORTS"]
Makefile = joinpath(srcdir, "Makefile")

function find_obj(makefile_path=Makefile)
    makefile = readall(makefile_path)
    m = match(r"libsdp\.a\:(.+)", makefile)
    m != nothing || error("Could not find `libsdp.a` target in '$makefile_path'")
    objs = matchall(r"\w+\.o", m.captures[1])
    objs = UTF8String[splitext(o)[1] for o in objs]
end


function compile_objs()
    for o in find_obj()
        run(`gcc -fPIC $cflags -o $builddir/$o.o -c $srcdir/$o.c`)
    end
    objs = ["$builddir/$o.o" for o in find_obj()]
    libs = ["-l$l" for l in ["blas", "lapack"]]
    cmd = `gcc -shared -o $dlpath $objs $libs`
    try
        run(cmd)
    catch
        println(cmd)
    end
end


provides(Sources,
         URI("http://www.coin-or.org/download/source/Csdp/Csdp-$version.tgz"),
         csdp,
         unpacked_dir="Csdp-$version")


provides(SimpleBuild,
         (@build_steps begin
             GetSources(csdp)
             CreateDirectory(libdir)
             CreateDirectory(builddir)
             @build_steps begin
                  ChangeDirectory(srcdir)
                  compile_objs
             end
         end),
         [csdp])


# TODO: provide win32 binaries
# http://icl.cs.utk.edu/lapack-for-windows/lapack/#libraries_mingw
provides(Binaries,
   URI("http://icl.cs.utk.edu/lapack-for-windows/libraries/VisualStudio/3.6.0/Dynamic-MINGW/Win64/liblapack.dll"),
   [lapack], unpacked_dir="bin$WORD_SIZE", os = :Windows)

provides(Binaries,
   URI("http://icl.cs.utk.edu/lapack-for-windows/libraries/VisualStudio/3.6.0/Dynamic-MINGW/Win64/libblas.dll"),
   [blas], unpacked_dir="bin$WORD_SIZE", os = :Windows)


@BinDeps.install Dict(:csdp => :csdp)
