
structure PgDb :> DB where type sql = string
                     where type Handle.db = Postgresql.db =
  PgDbFn (struct
            type sql = string
            fun sql2s s = s
            fun s2sql s = s
          end)
