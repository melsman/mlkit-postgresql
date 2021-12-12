(** Low-level Postgresql signature

This signature specifies low-level functionality for interacting with
a postgresql database.

*)

signature POSTGRESQL = sig

  type db

  exception PgError of string

  val connect   : string -> db         (* may raise PgError *)
  val finish    : db -> unit
  val exec      : db * string -> unit  (* may raise PgError *)
  val errmsg    : db -> string

  type res

  val query     : db * string -> res   (* may raise PgError *)
  val clear     : res -> unit
  val ntuples   : res -> int
  val nfields   : res -> int
  val getvalue  : res * int * int -> string
  val getisnull : res * int * int -> bool
  val fnumber   : res * string -> int
  val fname     : res * int -> string

end
