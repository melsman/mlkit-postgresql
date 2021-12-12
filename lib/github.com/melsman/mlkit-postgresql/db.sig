(** Generic database signature with operations fixed to use a single
    database connection.

This signature specifies generic RDBMS functionality where functions
make use of a single database connection.

*)

signature DB = sig

  exception DbError of string

  structure Handle    : DB_HANDLE

  type sql = Handle.sql

  (* Connectivity *)
  val doconnect       : string -> unit
  val deconnect       : unit -> unit
  val setconn         : Handle.db -> unit

  (* Data manipulation language *)
  val dml             : sql -> unit
  val errmsg          : unit -> string

  (* Queries *)
  val fold            : ((string->string)*'a->'a) -> 'a -> sql -> 'a
  val foldRaw         : (string option list * 'a -> 'a) -> 'a -> sql -> 'a
  val app             : ((string->string)->'a) -> sql -> unit
  val list            : ((string->string)->'a) -> sql -> 'a list
  val oneField        : sql -> string
  val zeroOrOneField  : sql -> string option
  val zeroOrOneRow    : sql -> string list option
  val zeroOrOneRow'   : ((string->string)->'a) -> sql -> 'a option

  (* Transactions *)
  val begin           : unit -> unit
  val commit          : unit -> unit
  val rollback        : unit -> unit
  val transaction     : (unit -> 'a) -> 'a
  val transactionConn : (Handle.db -> 'a) -> 'a

  (* Sequences *)
  val seqNextval      : string -> int
  val seqCurrval      : string -> int

  (* Miscellaneous *)
  val seqNextvalExp   : string -> string
  val seqCurrvalExp   : string -> string
  val sysdateExp      : string
  val qq              : string -> string
  val qqq             : string -> string
  val toDate          : string -> Date.date option
  val timestampType   : string
  val toTimestampExp  : string -> string
  val toTimestamp     : string -> Date.date option
  val fromDate        : Date.date -> string
  val toDateExp       : string -> string
  val valueList       : string list -> string
  val setList         : (string*string) list -> string
  val toBool          : string -> bool option
  val fromBool        : bool -> string
  val toReal          : string -> real option
  val fromReal        : real -> string
end

(**

Description:

[structure Handle] contains handle-specific operations, which allows
for maintaining multiple database connections.

[doconnect conninfo] initiates a connection to the underlying database
specified by the connection string `conninfo`.

[deconnect()] closes the connection.

[dml cmd] executes the data manipulation language command `cmd`
assuming an open database connection. Raises `DbError msg` on error;
`msg` is the error message returned from the database.

[fold f b sql] executes the `sql` query (assuming an open database
connection) and folds over the result set with `b` as the base and `f`
as the fold function; the first argument to `f` is a function that
maps column names to values. Raises `DbError msg` on error.

[foldRaw f b sql] similar to fold except that f receives a row and an
accumulator as its arguments. Raises `DbError msg` on error, but does
no checking of column names.

[app f sql] executes `sql` query (assuming an open database
connection) and applies f on each row in the result set. Raises
`DbError msg` on error.

[list f sql] executes `sql` query (assuming an open database
connection) and applies f on each row in the result set. The result
elements are returned as a list. Raises `DbError msg` on error.

[oneField sql] executes `sql` query (assuming an open database
connection), which must return exactly one row with one column, which
the function returns as a string. Raises `DbError msg` on error.

[zeroOrOneField sql] executes `sql` query, which must return either
zero or one row. If one row is returned then there must be exactly one
column in the row. Raises `DbError msg` on error.

[oneRow sql] executes `sql` query, which must return exactly one
row. Returns all columns as a list of strings. Raises `DbError msg` on
error.

[oneRow' f sql] executes `sql` query, which must return exactly one
row. Returns f applied on the row. Raises `DbError msg` on error.

[zeroOrOneRow sql] executes `sql` query, which must return either zero
or one row. Returns all columns as a list of strings. Raises `DbError
msg` on error.

[zeroOrOneRow' f sql] executes `sql` query, which must return either
zero or one row. Returns f applied on the row if a row exists. Raises
`DbError msg` on error.

[existsOneRow sql] executes `sql` query and returns true if the query
results in one or more rows; returns false, otherwise. Raises `DbError
msg` on error.

[seqNextvalExp seq_name] returns a string to fit in an SQL statement
generating a new number from sequence `seq_name`.

[seqNextval seq_name] executes SQL statement to generate a new number
from sequence seq_name. Raise `DbError msg` on error.

[seqCurrvalExp seq_name] returns a string to fit in an SQL statement
returning the current number from the sequence `seq_name`.

[seqCurrval seq_name] executes SQL statement to get the current number
from sequence `seq_name`. Raises `DbError msg` on error.

[sysdateExp] returns a string representing the current date to be used
in an SQL statement (to have your application support different
database vendors).

[qq v] returns a string with each quote (') replaced by double quotes
('') (e.g., qq("don't go") = "don''t go").

[qqq v] similar to qq except that the result is encapsulated by quotes
(e.g., qqq("don't go") = "'don''t go'").

[toDate d] returns the Date.date representation of `d`, where `d` is
the date representation used in the particular database. Returns NONE
if `d` cannot be converted into a Date.date. Only year, month and day
are considered.

[toBool b] returns the Bool.bool representation of a boolean, where
`b` is the bool representation used in the particular
database. Returns NONE if `b` cannot be converted into a Bool.bool.

[timestampType] returns the database type (as a string) representing a
timestamp (to have your application support different database
vendors).

[toTimestampExp d] returns a string to put in a select statement,
which will return a timestamp representation of column `d`. Example:
`select ^(Db.toTimestampExp "d") from t` where `d` is a column of type
date (in oracle) or datatime (in PostgreSQL and MySQL).

[toTimestamp t] returns the Date.date representation of `t`, where `t`
is the timestap representation from the database. Returns NONE if `t`
cannot be converted into a Date.date. Year, month, day, hour, minutes
and seconds are considered.

[fromDate d] returns a string to be used in an SQL statement to insert
the date `d` in the database.

[fromBool b] returns a Bool.bool used in an SQL statement to insert
the boolean `b` in the database.

[valueList vs] returns a string formatted to be part of an insert
statement:

       `insert into t (f1,f2,f3)
        values (^(Db.valueList [f1,f2,f3]))`

is turned into

      `insert into t (f1,f2,f3)
       values ('f1_','f2_','f3_')`

where `fi_` are the properly quoted values.

[setList nvs] returns a string formatted to be part of an update
statement. Say `nvs = [(n1,v1),(n2,v2)]`, then

       `update t set ^(Db.setList nvs)`

is turned into

       `update t set n1='v1_',n2='v2_'`

where `vi_` are the properly quoted values.

*)
