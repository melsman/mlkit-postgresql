(** Generic database signature with functionality indexed over
    connection handles.

This signature specifies generic RDBMS functionality where functions
are indexed over database connection handles, which allows for
maintaining multiple simultaneous database connections.

*)

signature DB_HANDLE = sig
  type db

  type sql

  (* Data manipulation language *)
  val dml            : db -> sql -> unit
  val errmsg         : db -> string

  (* Queries *)
  val fold           : db -> ((string->string)*'a->'a) -> 'a -> sql -> 'a
  val foldRaw        : db -> (string option list * 'a -> 'a) -> 'a -> sql -> 'a
  val app            : db -> ((string->string)->'a) -> sql -> unit
  val list           : db -> ((string->string)->'a) -> sql -> 'a list
  val oneField       : db -> sql -> string
  val zeroOrOneField : db -> sql -> string option
  val zeroOrOneRow   : db -> sql -> string list option
  val zeroOrOneRow'  : db -> ((string->string)->'a) -> sql -> 'a option

  (* Transactions *)
  val begin          : db -> unit
  val commit         : db -> unit
  val rollback       : db -> unit
  val transaction    : db -> (db -> 'a) -> 'a

  (* Sequences *)
  val seqNextval     : db -> string -> int
  val seqCurrval     : db -> string -> int
end
