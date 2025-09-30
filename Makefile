.PHONY: clean examples check dca

dca:
	dune build -p dead_code_analyzer

check:
	make -C check

examples:
	make -C examples

clean:
	dune clean
	make -C examples clean
	make -C check clean
