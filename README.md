# # sml-parse [![CI](https://github.com/diku-dk/sml-parse/workflows/CI/badge.svg)](https://github.com/diku-dk/sml-parse/actions)

Postgresql library for Standard ML / MLKit

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

There are two versions of the __PgDb__ and __PgDb.Handle__ structures,
one that treats SQL code as Standard ML strings (available through
`pgdb.mlb`) and one that treats SQL code as MLKit quotations
(available through `pgdb-quot.mlb`), which requires `-quot` to be
passed to `mlkit`.

## Overview of MLB files

- `lib/github.com/melsman/mlkit-postgresql/pgdb.mlb`:

  - **structure** `PgDb` :> `DB where type sql = string`

- `lib/github.com/melsman/mlkit-postgresql/pgdb-quot.mlb`:

  - **structure** `PgDb` :> `DB where type sql = quot`

- `lib/github.com/melsman/mlkit-postgresql/pgdb-fn.mlb`:

  - **signature** [`DB`](lib/github.com/melsman/mlkit-postgresql/db.sig)
  - **signature** [`DB_HANDLE`](lib/github.com/melsman/mlkit-postgresql/db-handle.sig)
  - **functor** `PgDbFn` : `(X : ...) -> DB`

- `lib/github.com/melsman/mlkit-postgresql/postgresql.mlb`:

  - **signature** [`POSTGRESQL`](lib/github.com/melsman/mlkit-postgresql/postgresql.sig)
  - **structure** `Postgresql` :> `POSTGRESQL`


## Assumptions

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

## Use of the package

This library is set up to work well with the SML package manager
[smlpkg](https://github.com/diku-dk/smlpkg).  To use the package, in
the root of your project directory, execute the command:

```
$ smlpkg add github.com/melsman/mlkit-postgresql
```

This command will add a _requirement_ (a line) to the `sml.pkg` file
in your project directory (and create the file, if there is no file
`sml.pkg` already).

To download the library into the directory
`lib/github.com/melsman/mlkit-postgresql` (along with other necessary
libraries), execute the command:

```
$ smlpkg sync
```

You can now reference the `mlb`-file using relative paths from within
your project's `mlb`-files.

Notice that you can choose either to treat the downloaded package as
part of your own project sources (vendoring) or you can add the
`sml.pkg` file to your project sources and make the `smlpkg sync`
command part of your build process.


## Authors

Copyright (c) 2019-2021 Martin Elsman, University of Copenhagen.

## License

See [LICENSE](LICENSE) (MIT License).
