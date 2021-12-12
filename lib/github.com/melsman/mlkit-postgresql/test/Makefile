POSTGRESQL_INCLUDEDIR ?= /usr/include/postgresql

OPT:=-Wall -std=gnu99 -g -O2
CFLAGS=-DTAG_VALUES -DTAG_FREE_PAIRS -DENABLE_GC $(OPT) -I $(POSTGRESQL_INCLUDEDIR)

MLKIT ?= mlkit

.PHONY: all
all: test

.PHONY: test
test: test.res
	cat $^

test.exe: test.mlb test.sml
	$(MAKE) -C .. lib
	$(MLKIT) -quot -o $@ -libdirs ".." -libs "smlpq,pq,m" $<

# simple c-test of libpq
ctest: testlibpq.c
	gcc $(CFLAGS) testlibpq.c -lpq
	./a.out

.PHONY: init
init:
	dropdb --if-exists dbtest
	createdb dbtest
	psql -f dbtest_schema.sql dbtest

%.out: %.exe init
	./$< > $@

%.res: %.out
	@(diff -aq $< $<.ok > /dev/null 2>&1; \
         if [ $$? -eq 0 ]; then \
             echo "OK:  $*" > $@ \
         ; else \
             if [ -e $<.ok ]; then \
                echo "ERR: $* - file $< differs from $<.ok"; \
                echo "ERR: $* - file $< differs from $<.ok" > $@ \
             ; else \
                echo "ERR: $* - file $<.ok does not exist"; \
                echo "ERR: $* - file $<.ok does not exist" > $@ \
             ; fi \
             ; exit 1 \
         ;fi)

.PHONY: clean
clean:
	rm -rf a.out *~ *.o *.a *.exe MLB a.out.dSYM *.res *.out
	dropdb --if-exists dbtest
