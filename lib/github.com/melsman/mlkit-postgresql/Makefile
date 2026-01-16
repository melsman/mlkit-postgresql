
OPT := -Wall -std=gnu99 -g -O2
CFLAGS = -DTAG_VALUES -DTAG_FREE_PAIRS -DENABLE_GC $(OPT)

ifeq ($(shell uname),Darwin)
MLKIT_INCLUDEDIR ?= /usr/local/share/mlkit/include/
POSTGRESQL_INCLUDEDIR ?= /usr/local/include/postgresql@14
POSTGRESQL_LIBDIR ?= /usr/local/lib/postgresql@14
CFLAGS += -arch x86_64
else
MLKIT_INCLUDEDIR ?= /usr/share/mlkit/include/
POSTGRESQL_INCLUDEDIR ?= /usr/include/postgresql
POSTGRESQL_LIBDIR ?= /usr/lib/postgresql
endif

MLKIT ?= mlkit

SRCFILES = $(shell ls -1 *.sml *.sig)

.PHONY: lib
lib: libsmlpq.a

.PHONY: all
all: lib pgdb.exe pgdb-quot.exe

libsmlpq.a: libsmlpq.c Makefile
	gcc $(CFLAGS) -c -I $(MLKIT_INCLUDEDIR) -I $(POSTGRESQL_INCLUDEDIR) -o $@ $<

# Two versions: one with sql strings being quotations and one with
# sql strings being SML strings.

pgdb-quot.exe: pgdb-quot.mlb $(SRCFILES) libsmlpq.a
	$(MLKIT) -quot -o $@ -libdirs ".,$(POSTGRESQL_LIBDIR)" -libs "smlpq,pq,m" $<

pgdb.exe: pgdb.mlb $(SRCFILES) libsmlpq.a
	$(MLKIT) -o $@ -libdirs ".,$(POSTGRESQL_LIBDIR)" -libs "smlpq,pq,m" $<

.PHONY: test
test:
	$(MAKE) -C test test

.PHONY: clean
clean:
	rm -rf a.out *~ *.o *.a *.exe MLB
	$(MAKE) -C test clean
