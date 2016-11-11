csdp   = Csdp-6.1.1
libs   = -lblas -llapack
build  = ../build
CFLAGS = -DNOSHORTS -I$(csdp)/include -g

CFLAGS64=-O3 -ansi -Wall -DNOSHORTS -DUSEGETTIME -I../include -Dinteger=long -fopenmp -g -m64


srcs = $(shell ls $(csdp)/lib/*.c)
objs = $(patsubst $(csdp)/lib/%.c,$(build)/%.o,$(srcs))

$(build)/%.o: $(csdp)/lib/%.c
	$(CC) -c -fPIC $(CFLAGS) -o $@ $<

../usr/lib/libcsdp.so: $(objs)
	$(LD) -shared -o $@ $(libs) $^
