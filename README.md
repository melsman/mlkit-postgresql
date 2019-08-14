## Postgresql library for Standard ML / MLKit

This library provides access to the postgresql database from within
SML using the `libpq` API. The functionality is provided through
several layers:

- _High-level API_. Structure __PgDb : [DB](src/db.sig)__.

- _Medium-level API_. Structure __PgDb.Handle : [DB_HANDLE](src/db.sig)__.

- _Low-level API_. Structure __Postgresql : [POSTGRESQL](src/postgresql.sig)__.

With the medium-level and low-level APIs, the programmer manages and
propagates connection information explicitly, whereas, with the
high-level API, a single connection is setup and managed through
side-effecting functions.

### Assumptions

A working MLKit installation (see
https://github.com/melsman/mlkit). Use `brew install mlkit` on macOS.

### Testing

To test the library, first do as follows:

    $ cd src
    $ make

Notice that, dependent on the architecture, you may need first to set the
environment variable `MLKIT_INCLUDEDIR` to something different than
the default value `/usr/share/mlkit/include/`. For instance, if you
use `brew` under macOS, you should do as follows:

    $ cd src
    $ MLKIT_INCLUDEDIR=/usr/local/share/mlkit/include/ make

Then, proceed as follows:

    $ cd ../test
    $ make init
    $ make

Notice that it may be necessary to tweak the
[src/Makefile](src/Makefile) and the [test/Makefile](test/Makefile) to
specify the location of the MLKit compiler binary, the MLKit include
files, and the MLKit basis library.

### License

See [LICENSE](LICENSE) (MIT License).