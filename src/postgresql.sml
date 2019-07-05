structure Postgresql :> POSTGRESQL = struct

type conn = foreignptr
type res = foreignptr

exception PgError of string

fun isNullFptr (f:foreignptr) : bool =
    prim("smlpq_fptr_isnull", f)

fun connect (conninfo:string) : conn =
    let val c : conn = prim("smlpq_connect", conninfo)
    in if isNullFptr c then raise PgError "connect"
       else c
    end

fun finish (conn:conn) : unit =
    prim("smlpq_finish", conn)

fun errmsg (conn:conn) : string =
    prim("smlpq_errorMessage", conn)

fun exec (conn:conn, cmd:string) : unit =
    let fun exec0 (conn:conn, cmd:string) : int =
            prim("smlpq_exec", (conn,cmd))
    in if exec0 (conn,cmd) <> ~1 then ()
       else raise PgError "exec"
    end

fun query (conn:conn, query:string) : res =
    let val r : res = prim("smlpq_query", (conn,query))
    in if isNullFptr r then raise PgError "query"
       else r
    end

fun clear (res:res) : unit =
    prim("smlpq_clear", res)

fun ntuples (res:res) : int =
    prim("smlpq_ntuples", res)

fun nfields (res:res) : int =
    prim("smlpq_nfields", res)

fun getvalue (res:res,r:int,c:int) : string =
    let val s : string = prim("smlpq_getvalue", (res,r,c))
    in if prim("__is_null", s) then raise PgError "getvalue"
       else s
    end

fun getisnull (res:res,r:int,c:int) : bool =
    prim("smlpq_getisnull", (res,r,c))

fun fnumber (res:res,f:string) : int =
    prim("smlpq_fnumber",(res,f))

fun fname (res:res,i:int) : string =
    prim("smlpq_fname",(res,i))

end
