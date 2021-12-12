infix |>
fun v |> f = f v

structure Db = PgDb

val () = print "[Testing PgDb]\n"

fun test_exn t f a =
    (print ("Test " ^ t ^ " : ");
     f a;
     print "ERR - expecting exn\n")
    handle Db.DbError _ => print ("OK\n")

fun test (t:string) (f: 'a -> string) (a:'a) (e:string) : unit =
    (print ("Test " ^ t ^ " : ");
     let val v = f a
     in if v = e then print "OK\n"
        else print ("ERR - expecting " ^ e ^ " - got " ^ v ^ "\n")
     end handle Db.DbError msg => print ("EXN - expected " ^ e ^ "; exn msg=" ^ msg ^ "\nMSG=" ^ Db.errmsg()))

val () = test_exn "test1" Db.doconnect "dbname = dbdoesnotexist"

val () = Db.doconnect "dbname=dbtest"

(* fold *)
val () = test "fold1" (Db.fold (fn (get,a) => a ^ "," ^ get "c") "")
              `select current_database() as c`
              ",dbtest"

val () = test "fold2" (Db.fold (fn (get,a) => a ^ "," ^ get "t") "")
              `SELECT table_name as t FROM information_schema.tables
                WHERE table_schema='public' AND table_type='BASE TABLE'`
              ",person,currency,cars"

val () = test "fold3" (Db.fold (fn (get,a) => a ^ "," ^ get "c") "")
              `select current_schema() as c`
              ",public"

val () = test "fold4" (Db.fold (fn (get,a) => a ^ "," ^ get "c") "")
              `select count(*) as c from currency`
              ",167"

val () = test "fold5" (Db.fold (fn (get,a) => a ^ "," ^ get "firstname") "")
              `select firstname from person`
              ",Hans,Grete,John"

val () = test_exn "fold6" (Db.fold (fn (get,a) => a ^ "," ^ get "wrongname") "")
              `select firstname from person`

val () = test_exn "fold7" (Db.fold (fn (get,a) => a ^ "," ^ get "firstname") "")
                  `select firstname from perrrson`

(* foldRaw *)

fun o2s NONE = "_" | o2s (SOME s) = s
fun l2s l = "[" ^ String.concatWith "," l ^ "]"
fun ol2s l = "[" ^ String.concatWith "," (map o2s l) ^ "]"
fun lo2s (SOME l) = "[" ^ String.concatWith "," l ^ "]"
  | lo2s NONE = "_"

val () = test "foldRaw1" (Db.foldRaw (fn (vs,a) => a ^ "," ^ ol2s vs) "")
              `select firstname,age,phone from person where firstname = 'John'`
              ",[John,52,_]"

val () = test_exn "foldRaw2" (Db.foldRaw (fn (vs,a) => a ^ "," ^ ol2s vs) "")
                  `select firstname from perrrson`

(* app *)
val r = ref ""
val () = test_exn "app1" (Db.app (fn get => r := "no"))
                  `select firstname from peeerson`

val () = test_exn "app2" (Db.app (fn get => r := get "age"))
                  `select firstname from person`

val () = test "app3" ((fn () => !r) o Db.app (fn get => r := get "firstname"))
              `select firstname from person where firstname = 'John'`
              "John"

val () = test "app4" ((fn () => !r) o Db.app (fn get => r := get "firstname"))
              `select firstname from person order by firstname desc`
              "Grete"

val () = test "app5" ((fn () => !r) o Db.app (fn get => r := get "firstname"))
              `select firstname from person order by firstname`
              "John"

(* list *)
val () = test_exn "list1" (Db.list (fn get => get "firstname"))
                  `select firstname from peeerson`

val () = test_exn "list2" (Db.list (fn get => get "fiiiirstname"))
                  `select firstname from person`

val () = test "list3" (l2s o Db.list (fn get => get "firstname"))
              `select firstname from person`
              "[Hans,Grete,John]"

val () = test "list4" (l2s o Db.list (fn get => get "firstname"))
              `select firstname from person where firstname = 'noone'`
              "[]"

val () = test "list5" (l2s o Db.list (fn get => get "firstname"))
              `select firstname from person where firstname = 'John'`
              "[John]"

(* oneField *)
val () = test "oneField1" Db.oneField
              `select firstname from person where firstname = 'John'`
              "John"

val () = test_exn "oneField2" Db.oneField
                  `select firstname from person`

val () = test_exn "oneField3" Db.oneField
                  `select firstname from person where firstname = 'noone'`

val () = test_exn "oneField4" Db.oneField
                  `select firstname from pedfdfrson`

val () = test_exn "oneField5" Db.oneField
                  `select firstname,lastname from person where firstname = 'John'`

(* zeroOrOneField *)
val () = test "zeroOrOneField1" (o2s o Db.zeroOrOneField)
              `select firstname from person where firstname = 'John'`
              "John"

val () = test "zeroOrOneField2" (o2s o Db.zeroOrOneField)
              `select firstname from person where firstname = 'noone'`
              "_"

val () = test_exn "zeroOrOneField3" (o2s o Db.zeroOrOneField)
                  `select firstname,lastname from person where firstname = 'John'`

val () = test_exn "zeroOrOneField4" (o2s o Db.zeroOrOneField)
                  `select firstname from pesdsdrson where firstname = 'John'`

(* zeroOrOneRow *)
val () = test "zeroOrOneRow1" (lo2s o Db.zeroOrOneRow)
              `select firstname,lastname from person where firstname = 'John'`
              "[John,Hansen]"

val () = test "zeroOrOneRow2" (lo2s o Db.zeroOrOneRow)
              `select firstname,lastname from person where firstname = 'noone'`
              "_"

val () = test_exn "zeroOrOneRow3" (lo2s o Db.zeroOrOneRow)
                  `select firstname,lastname from person`

val () = test_exn "zeroOrOneRow4" (lo2s o Db.zeroOrOneRow)
                  `select fisdsrstname,lastname from person`

val () = test "zeroOrOneRow5" (lo2s o Db.zeroOrOneRow)
              `select firstname from person where firstname = 'John'`
              "[John]"

(* zeroOrOneRow' *)
val () = test "zeroOrOneRow'1" (o2s o Db.zeroOrOneRow' (fn get => get "firstname" ^ " " ^ get "lastname"))
              `select firstname,lastname from person where firstname = 'John'`
              "John Hansen"

val () = test "zeroOrOneRow'2" (o2s o Db.zeroOrOneRow' (fn get => get "firstname"))
              `select firstname,lastname from person where firstname = 'noone'`
              "_"

val () = test_exn "zeroOrOneRow'3" (o2s o Db.zeroOrOneRow' (fn get => get "age"))
                  `select firstname,lastname from person`

val () = test_exn "zeroOrOneRow'4" (o2s o Db.zeroOrOneRow' (fn get => get "firstname"))
                  `select fisdsrstname,lastname from person`

val () = test "zeroOrOneRow'5" (o2s o Db.zeroOrOneRow' (fn get => get "firstname"))
              `select firstname,age from person where firstname = 'John'`
              "John"

(* seqNextval *)
val () = test "seqNextval1" (fn seq => if 102 < Db.seqNextval seq then "OK"
                                       else "ERR")
              "pid_seq"
              "OK"

val () = test "seqNextval2" (fn seq => if Db.seqNextval seq < Db.seqNextval seq then "OK"
                                       else "ERR")
              "pid_seq"
              "OK"

val () = test_exn "seqNextval3" (fn seq => if Db.seqNextval seq < Db.seqNextval seq then "OK"
                                           else "ERR")
                  "pid_ssdsdeq"

(* seqCurrval *)
val () = test_exn "seqCurrval1" (fn seq => if 100 < Db.seqCurrval seq then "OK"
                                           else "ERR")
                  "pid_ssdsdeq"

val () = test "seqCurrval2" (fn seq => if Db.seqNextval seq = Db.seqCurrval seq then "OK"
                                       else "ERR")
              "pid_seq"
              "OK"

(* dml *)

val () = Db.dml `delete from cars`

val () = test "car1" Db.oneField
              `select count(*) from cars`
              "0"

val () = Db.dml `insert into cars (brand,model,cyear)
                             values ('Mercedes', 'E220d', 2018),
                                    ('Audi', 'A6', 2006),
                                    ('VW', 'Golf', 2001)`

val () = test "car2" Db.oneField
              `select count(*) from cars`
              "3"

val () = Db.begin()

val () = Db.dml `insert into cars (brand,model,cyear)
                             values ('Ford', 'Focus', 2008)`

val () = test "car3" Db.oneField
              `select count(*) from cars`
              "4"

val () = Db.rollback()

val () = test "car4" Db.oneField
              `select count(*) from cars`
              "3"

val () = Db.begin()

val () = Db.dml `insert into cars (brand,model,cyear)
                             values ('Audi', 'A3', 2013)`

val () = Db.commit()

val () = test "car5" Db.oneField
              `select count(*) from cars`
              "4"
(*
val () = Db.commit()
val () = Db.rollback()
*)

val () = Db.deconnect()

(* toDate and toTimestamp *)

val () = test "toDate-1" (Date.fmt "%Y--%m--%d" o Option.valOf o Db.toDate) "2021-10-23" "2021--10--23"

val () = test "toTimestamp-1" (Date.fmt "%Y--%m--%d %H.%M.%S" o Option.valOf o Db.toTimestamp) "2021-10-23 22:12:45" "2021--10--23 22.12.45"

val () = print "[Testing PgDb DONE]\n"
