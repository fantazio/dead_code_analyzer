all: build analyze

build:
	make -C to_incl
	make -C incl_without_intf
	make -C incl_with_intf
	make -C coincide_locations

analyze:
	dead_code_analyzer --nothing -E all .

clean:
	rm -f *.cm* *.o a.out
	make -C to_incl clean
	make -C incl_without_intf clean
	make -C coincide_locations clean
