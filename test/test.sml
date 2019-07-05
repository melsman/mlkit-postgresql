structure Db = PgDb

val () = print "[Testing PgDb]\n"
fun pr_test s = print("Testing " ^ s ^ "\n")

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
              ",person,currency"

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

val () = pr_test "fold"
val s = Db.fold (fn (get,a) => a ^ "," ^ get "datname") "" `select datname from pg_database`
        handle _ => Db.errmsg()

val () = print ("s is " ^ s ^ "\n")

val () = Db.deconnect()
