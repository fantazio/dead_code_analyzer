COMPFLAGS=-g -w +A-4-9-40-42 -bin-annot -keep-locs
OCAMLC=ocamlc $(COMPFLAGS)
OCAMLOPT=ocamlopt $(COMPFLAGS)
OCAML_VERSION=$(shell ocamlc -version)

ADD_UNIX=$(shell [ $(OCAML_VERSION) \< 5.1 ] && echo "YES")
ifeq ($(ADD_UNIX), YES)
OCAMLC:=$(OCAMLC) -I +unix unix.cma
OCAMLOPT:=$(OCAMLOPT) -I +unix unix.cmxa
endif

API_SRC=io.ml pretty_print.ml section.ml scores.ml path.ml reports.ml
CHECK_SRC=$(API_SRC:.ml=.mli) $(API_SRC) check.mli check.ml
AGGR_SRC=$(API_SRC:.ml=.mli) $(API_SRC) aggregate.mli aggregate.ml

check.byt$(EXE): $(CHECK_SRC)
	$(OCAMLC) -o $@ $^

check.opt$(EXE): $(CHECK_SRC)
	$(OCAMLOPT) -o $@ $^

aggregate.byt$(EXE): $(AGGR_SRC)
	$(OCAMLC) -o $@ $^

aggregate.opt$(EXE): $(AGGR_SRC)
	$(OCAMLOPT) -o $@ $^

io.ml: io.cppo.ml
	cppo -V OCAML:$(OCAML_VERSION) -o $@ $^

clean:
	rm -f io.ml *~ *.cm* *.a *.lib *.o *.obj *.byt$(EXE) *.opt$(EXE) **.out
