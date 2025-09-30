.PHONY: clean run_dca build_dca build_dune build_make build dune_only make_only

CMTI_ROOT?=. ../_build/default/examples/using_dune

all: build build_dca run_dca

make_only: build_make build_dca
	make run_dca CMTI_ROOT="."

dune_only: build_dune build_dca
	make run_dca CMTI_ROOT="../_build/default/examples/using_dune"

build: build_make build_dune

build_make:
	make -C using_make

build_dune:
	dune build using_dune

build_dca:
	make -C .. dca

run_dca:
	../_build/install/default/bin/dead_code_analyzer $(DEADFLAGS) $(CMTI_ROOT)

clean:
	rm -f *~ *.cm* *.o *.obj
	make -C using_make clean
	dune clean
