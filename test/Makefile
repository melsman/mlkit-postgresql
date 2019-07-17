
KIT="/usr/lib/mlkit"

OPT:=-Wall -std=gnu99 -g -O2
CFLAGS=-DTAG_VALUES -DTAG_FREE_PAIRS -DENABLE_GC $(OPT)

KITHFILES=$(KIT)/src/Runtime

MLKIT=SML_LIB=$(KIT) mlkit -quot

all: test.exe
	./test.exe

test.exe: test.mlb test.sml
	$(MLKIT) -o $@ -libdirs "../src" -libs "smlpq,pq,m" $<

# simple c-test of libpq
ctest: testlibpq.c
	gcc $(CFLAGS) testlibpq.c -lpq
	./a.out

.PHONY: init
init:
	make -C ../src
	createdb dbtest
	psql -f dbtest_schema.sql dbtest

.PHONY: clean
clean:
	rm -rf a.out *~ *.o *.a *.exe MLB
	dropdb --if-exists dbtest
