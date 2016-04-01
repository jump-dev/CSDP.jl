using BinDeps

@BinDeps.setup

const version = "6.1.1"
libname = "libcsdp.$(Libdl.dlext)"
csdp = library_dependency("csdp", aliases=[libname])
srcdir = joinpath(BinDeps.depsdir(csdp), "src", "Csdp-$version", "lib")
prefix = joinpath(BinDeps.depsdir(csdp), "usr")
libdir = joinpath(prefix, "lib/")
builddir = joinpath(BinDeps.depsdir(csdp), "build")
dlpath = joinpath(libdir, libname)
cflags = "-I$srcdir/../include"
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
    cmd = `gcc -shared -o $dlpath $objs`
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


@BinDeps.install Dict(:csdp => :csdp)
