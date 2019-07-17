OPT:=-Wall -std=gnu99 -g -O2
CFLAGS=-DTAG_VALUES -DTAG_FREE_PAIRS -DENABLE_GC $(OPT)

MLKIT_INCLUDEDIR?="/usr/share/mlkit/include/"

all: libsmlpq.a

libsmlpq.a: libsmlpq.c Makefile
	gcc $(CFLAGS) -c -I $(MLKIT_INCLUDEDIR) -I /usr/include/postgresql -o $@ $<

.PHONY: clean
clean:
	rm -rf a.out *~ *.o *.a *.exe MLB
