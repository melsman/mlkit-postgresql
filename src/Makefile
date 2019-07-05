
KIT=`pwd`/../../mlkit

OPT:=-Wall -std=gnu99 -g -O2
CFLAGS=-DTAG_VALUES -DTAG_FREE_PAIRS -DENABLE_GC $(OPT)

KITHFILES=$(KIT)/src/Runtime

all: libsmlpq.a

libsmlpq.a: libsmlpq.c Makefile
	gcc $(CFLAGS) -c -I $(KITHFILES) -o $@ $<

.PHONY: clean
clean:
	rm -rf a.out *~ *.o *.a *.exe MLB
