structure PgDb :> DB where type sql = quot
                     where type Handle.db = Postgresql.db =
  PgDbFn (struct
            type sql = quot
            fun sql2s (q : quot) : string =
                concat(map (fn QUOTE s => s | ANTIQUOTE s => s) q)
            fun s2sql s : quot = `^s`
          end)
