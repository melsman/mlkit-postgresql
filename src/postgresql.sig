(* Copyright 2019, Martin Elsman. MIT License.
   Low-level Postgresql API.
   Consider using the higher-level DB API, instead.
*)

signature POSTGRESQL = sig
  type conn
  exception PgError of string

  val connect   : string -> conn          (* may raise PgError *)
  val finish    : conn -> unit
  val exec      : conn * string -> unit   (* may raise PgError *)
  val errmsg    : conn -> string

  type res
  val query     : conn * string -> res    (* may raise PgError *)
  val clear     : res -> unit
  val ntuples   : res -> int
  val nfields   : res -> int
  val getvalue  : res * int * int -> string
  val getisnull : res * int * int -> bool
  val fnumber   : res * string -> int
  val fname     : res * int -> string
end
