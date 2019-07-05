local

(* Quot-utilities *)
fun q2s (q : quot) : string =
    concat(map (fn QUOTE s => s | ANTIQUOTE s => s) q)

fun seqNextvalExp seq_name = "nextval('" ^ seq_name ^ "')"
fun seqCurrvalExp seq_name = "currval('" ^ seq_name ^ "')"

structure PgDbHandle :> DB_HANDLE where type conn = Postgresql.conn =
  struct
    structure Pg = Postgresql
    type conn = Pg.conn

    fun dml c q = Pg.exec(c,q2s q)
    fun errmsg c = Pg.errmsg c

    fun fold (c:conn) (f:(string->string)*'a->'a) (a:'a) (q:quot) : 'a =
        let val res = Pg.query (c, q2s q)
            val n = Pg.ntuples res
            val m = Pg.nfields res
            fun get i s =
                let val j = Pg.fnumber (res, s)
                in if j < 0 then raise Pg.PgError "fold.get"
                   else Pg.getvalue (res, i, j)
                end
            fun loop (i, a) =
                if i >= n then a
                else loop (i+1, f(get i,a))
        in loop (0, a) before Pg.clear res
        end

    fun mkrow (res,i,j,a) : string option list =
        if j < 0 then a
        else mkrow (res,i,j-1,
                    (if Pg.getisnull(res,i,j-1) then NONE
                     else SOME (Pg.getvalue(res,i,j-1)))::a)

    fun foldRaw (c:conn) (f:string option list*'a->'a) (a:'a) (q:quot) : 'a =
        let val res = Pg.query (c, q2s q)
            val n = Pg.ntuples res
            val m = Pg.nfields res
            fun loop (i, a) =
                if i >= n then a
                else loop (i+1, f(mkrow(res,i,m,nil),a))
        in loop (0, a) before Pg.clear res
        end

    fun app c (f:(string->string)->'a) q : unit =
        fold c (fn (g:string->string,()) => (f g; ())) () q

    fun list c f q =
        List.rev(fold c (fn (g,a) => f g::a) nil q)

    fun oneField c q =
        let val res = Pg.query (c, q2s q)
            val n = Pg.ntuples res
            val m = Pg.nfields res
        in if n <> 1 then
             (Pg.clear res;
              raise Pg.PgError ("oneField expects exactly one row - got " ^ Int.toString n))
           else if m <> 1 then
             (Pg.clear res;
              raise Pg.PgError ("oneField expects exactly one column - got " ^ Int.toString m))
           else Pg.getvalue(res,0,0) before Pg.clear res
        end

    fun zeroOrOneField c q : string option =
        let val res = Pg.query (c, q2s q)
            val n = Pg.ntuples res
            val m = Pg.nfields res
        in if n <> 1 andalso n <> 0 then
             (Pg.clear res;
              raise Pg.PgError ("zeroOrOneField expects either zero or one row - got " ^ Int.toString n))
           else if n = 0 then NONE before Pg.clear res
           else if m <> 1 then
             (Pg.clear res;
              raise Pg.PgError ("zeroOrOneField expects exactly one column - got " ^ Int.toString m))
           else SOME(Pg.getvalue(res,0,0)) before Pg.clear res
        end

    fun zeroOrOneRow c q : string list option =
        let val res = Pg.query (c, q2s q)
            val n = Pg.ntuples res
            val m = Pg.nfields res
        in if n <> 1 andalso n <> 0 then
             (Pg.clear res;
              raise Pg.PgError ("zeroOrOneRow expects either zero or one row - got " ^ Int.toString n))
           else if n = 0 then NONE before Pg.clear res
           else let val r = map (fn SOME v => v | NONE => "") (mkrow (res,0,m,nil))
                in SOME r before Pg.clear res
                end
        end

    fun zeroOrOneRow' c f q =
        case list c f q of
            nil => NONE
          | [x] => SOME x
          | l => raise Pg.PgError ("zeroOrOneRow' expects zero or one row - got " ^ Int.toString (length l))

    (* Sequences *)
    fun seqNextval c (seqName:string) : int =
	let val s = oneField c `select ^(seqNextvalExp seqName)`
	in case Int.fromString s of
	       SOME i => i
	     | NONE => raise Pg.PgError "seqNextval.nextval not an integer"
	end

    fun seqCurrval c (seqName:string) : int =
	let val s = oneField c `select ^(seqCurrvalExp seqName)`
	in case Int.fromString s of
	       SOME i => i
	     | NONE => raise Pg.PgError "seqCurrval.nextval not an integer"
	end
  end

in

structure PgDb :> DB =
  struct
    structure Pg = Postgresql
    exception DbError = Pg.PgError

    structure Handle = PgDbHandle

    (* Connectivity *)
    local val conn : Pg.conn option ref = ref NONE
    in fun doconnect (conninfo:string) : unit =
           conn := SOME (Pg.connect conninfo)
       fun deconnect () =
           case !conn of
               SOME c => (Pg.finish c before conn := NONE)
             | NONE => ()
       fun getconn () =
           case !conn of
               SOME c => c
             | NONE => raise DbError "no open db connection"
    end

    fun wrap f x = f (getconn()) x

    val dml = wrap Handle.dml
    fun errmsg () = Handle.errmsg (getconn())
    fun fold x = wrap Handle.fold x
    fun foldRaw x = wrap Handle.foldRaw x
    fun app x = wrap Handle.app x
    fun list x = wrap Handle.list x
    val oneField = wrap Handle.oneField
    val zeroOrOneField = wrap Handle.zeroOrOneField
    val zeroOrOneRow = wrap Handle.zeroOrOneRow
    fun zeroOrOneRow' x = wrap Handle.zeroOrOneRow' x
    val seqNextval = wrap Handle.seqNextval
    val seqCurrval = wrap Handle.seqCurrval

    val seqNextvalExp = seqNextvalExp
    val seqCurrvalExp = seqCurrvalExp
    val sysdateExp = "now()"
    fun fromDate d = "'" ^ (Date.fmt "%Y-%m-%d %H:%M:%S" d) ^ "'"
    fun toDateExp n = "to_char(" ^ n ^ ",'YYYY-MM-DD')"  (* Needs testing *)
    fun toTimestampExp d = "to_char(" ^ d ^ ",'YYYY-MM-DD HH24:MI:SS')"
    val timestampType = "timestamp"

    fun qq s =
      let fun qq_s' [] = []
	    | qq_s' (x::xs) = if x = #"'" then x :: x :: (qq_s' xs) else x :: (qq_s' xs)
      in implode(qq_s'(explode s))
      end

    fun qqq s = concat ["'", qq s, "'"]

    local
      fun mthToName mth =
	case mth of
	  1 => Date.Jan
	| 2 => Date.Feb
	| 3 => Date.Mar
	| 4 => Date.Apr
	| 5 => Date.May
	| 6 => Date.Jun
	| 7 => Date.Jul
	| 8 => Date.Aug
	| 9 => Date.Sep
	| 10 => Date.Oct
	| 11 => Date.Nov
	| 12 => Date.Dec
	| _ => raise DbError ("toDate: " ^ Int.toString mth)
    in
      fun toDate s =
	(case (RegExp.extract o RegExp.fromString) "([0-9][0-9][0-9][0-9])-([0-9][0-9])-([0-9][0-9]).*" s of
	     SOME [yyyy,mm,dd] => SOME (Date.date{year=Option.valOf (Int.fromString yyyy),
						  month=mthToName (Option.valOf (Int.fromString mm)),
						  day=Option.valOf (Int.fromString dd),
						  hour=0,minute=0,second=0,offset=NONE})
	   | _ => NONE)
	handle _ => NONE

      fun toTimestamp t =
	  (case (RegExp.extract o RegExp.fromString) "([0-9][0-9][0-9][0-9])-([0-9][0-9])-([0-9][0-9]) ([0-9][0-9]):([0-9][0-9]):([0-9][0-9]).*" t of
	       SOME [yyyy,mm,dd,h,m,s] => SOME (Date.date{year=Option.valOf (Int.fromString yyyy),
						          month=mthToName (Option.valOf (Int.fromString mm)),
						          day=Option.valOf (Int.fromString dd),
						          hour=Option.valOf(Int.fromString h),
						          minute=Option.valOf(Int.fromString m),
						          second=Option.valOf(Int.fromString s),
						          offset=NONE})
	     | _ => NONE)
	  handle _ => NONE
    end

    fun toBool "t" = SOME true
      | toBool "f" = SOME false
      | toBool _ = NONE

    fun fromBool true = "t"
      | fromBool false = "f"

    fun toReal r = Real.fromString r
    fun fromReal r = Real.toString r

    fun valueList vs = String.concatWith "," (List.map qqq vs)

    fun setList vs = String.concatWith (Quot.toString `,
`) (    List.map (fn (n,v) => n ^ "=" ^ qqq v) vs)

  end

end
