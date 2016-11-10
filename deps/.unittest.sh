unittest() { rm -fr usr/ && julia --color=yes -e 'Pkg.build("CSDP")' && julia --color=yes -e 'using CSDP; info("CSDP => $(CSDP.csdp)"); Pkg.test("CSDP")'; }
