/*
 * src/test/examples/testlibpq.c
 *
 *
 * testlibpq.c
 *
 *      Test the C version of libpq, the PostgreSQL frontend library.
 */
#include <stdio.h>
#include <stdlib.h>
#include "libpq-fe.h"
#include "String.h"
#include "Tagging.h"
#include "Runtime.h"

// Tagging scheme for foreign pointers: We need to tag the values as
// scalars so that the garbage collector won't trace the objects. This
// goes for pointers to values of type PGconn and pointers to values
// of type PGresult.

#define NULLVAL 1

//
// pass conninfo = "dbname = postgres";
// wrapper function should check for NULL
//
uintptr_t
smlpq_connect(String conninfo)
{
  PGconn *conn;
  conn = PQconnectdb(&(conninfo->data));

  if (PQstatus(conn) != CONNECTION_OK)
    {
      // fprintf(stderr, "smlpq ERROR: connection to database failed: %s", PQerrorMessage(conn));
      return (uintptr_t)(tag_scalar(NULL));
    }
  check_tag_scalar(conn);
  return (uintptr_t)(tag_scalar(conn));
}

String
REG_POLY_FUN_HDR(smlpq_errorMessage, Region rAddr, uintptr_t conn0)
{
  PGconn *conn = (PGconn *)untag_scalar(conn0);
  char *s = PQerrorMessage(conn);
  return REG_POLY_CALL(convertStringToML,rAddr,s);
}

long
smlpq_exec(uintptr_t conn0, String command)
{
  PGconn *conn = (PGconn *)untag_scalar(conn0);
  PGresult *res = PQexec(conn, &(command->data));
  if (PQresultStatus(res) != PGRES_COMMAND_OK)
    {
      PQclear(res);
      return convertIntToML(-1);
    }
  PQclear(res);
  return convertIntToML(0);
}

uintptr_t
smlpq_query(uintptr_t conn0, String query)
{
  PGconn *conn = (PGconn *)untag_scalar(conn0);
  PGresult *res = PQexec(conn, &(query->data));
  if (PQresultStatus(res) != PGRES_TUPLES_OK)
    {
      PQclear(res);
      res = NULL;
    }
  check_tag_scalar(res);
  return (uintptr_t)(tag_scalar(res));
}

void
smlpq_clear(uintptr_t res0)
{
  PGresult *res = (PGresult *)untag_scalar(res0);
  PQclear(res);
  return;
}

long
smlpq_ntuples(uintptr_t res0)
{
  PGresult *res = (PGresult *)untag_scalar(res0);
  return convertIntToML(PQntuples(res));
}

long
smlpq_nfields(uintptr_t res0)
{
  PGresult *res = (PGresult *)untag_scalar(res0);
  return convertIntToML(PQnfields(res));
}

String
REG_POLY_FUN_HDR(smlpq_getvalue, Region rAddr, uintptr_t res0, long r, long c)
{
  PGresult *res = (PGresult *)untag_scalar(res0);
  r = convertIntToC(r);
  c = convertIntToC(c);
  return REG_POLY_CALL(convertStringToML,rAddr,PQgetvalue(res,r,c));
}

long /*bool*/
smlpq_getisnull(uintptr_t res0, long r, long c)
{
  PGresult *res = (PGresult *)untag_scalar(res0);
  r = convertIntToC(r);
  c = convertIntToC(c);
  return convertBoolToML(PQgetisnull(res,r,c));
}

long /*bool*/
smlpq_fptr_isnull(uintptr_t v0)
{
  void *v = (void *)untag_scalar(v0);
  if (v == NULL) return mlTRUE;
  else return mlFALSE;
}

String
REG_POLY_FUN_HDR(smlpq_fname, Region rAddr, uintptr_t res0, long c)
{
  PGresult *res = (PGresult *)untag_scalar(res0);
  c = convertIntToC(c);
  return REG_POLY_CALL(convertStringToML,rAddr,PQfname(res,c));
}

long
smlpq_fnumber(uintptr_t res0, String f)
{
  PGresult *res = (PGresult *)untag_scalar(res0);
  return convertIntToML(PQfnumber(res,&(f->data)));
}

void
smlpq_finish(uintptr_t conn0)
{
  PGconn *conn = (PGconn *)untag_scalar(conn0);
  PQfinish(conn);
  return;
}

/*
 * TESTING STUFF
 */

long
smlpq_test(uintptr_t conn0)
{
  PGconn *conn = (PGconn *)untag_scalar(conn0);

  /*
   * Our test case here involves using a cursor, for which we must be inside
   * a transaction block.  We could do the whole thing with a single
   * PQexec() of "select * from pg_database", but that's too trivial to make
   * a good example.
   */

  /* Start a transaction block */
  PGresult *res = PQexec(conn, "BEGIN");
  if (PQresultStatus(res) != PGRES_COMMAND_OK)
    {
      fprintf(stderr, "BEGIN command failed: %s", PQerrorMessage(conn));
      PQclear(res);
      PQfinish(conn);
      exit(1);
    }
  PQclear(res);

  /*
   * Fetch rows from pg_database, the system catalog of databases
   */
  res = PQexec(conn, "DECLARE myportal CURSOR FOR select * from pg_database");
  if (PQresultStatus(res) != PGRES_COMMAND_OK)
    {
      fprintf(stderr, "DECLARE CURSOR failed: %s", PQerrorMessage(conn));
      PQclear(res);
      PQfinish(conn);
      exit(1);
    }
  PQclear(res);

  res = PQexec(conn, "FETCH ALL in myportal");
  if (PQresultStatus(res) != PGRES_TUPLES_OK)
    {
      fprintf(stderr, "FETCH ALL failed: %s", PQerrorMessage(conn));
      PQclear(res);
      PQfinish(conn);
      exit(1);
    }

  /* first, print out the attribute names */
  int nFields = PQnfields(res);
  for (int i = 0; i < nFields; i++)
    printf("%-15s", PQfname(res, i));
  printf("\n\n");

  /* next, print out the rows */
  for (int i = 0; i < PQntuples(res); i++)
    {
      for (int j = 0; j < nFields; j++)
	printf("%-15s", PQgetvalue(res, i, j));
      printf("\n");
    }

  PQclear(res);

  /* close the portal ... we don't bother to check for errors ... */
  res = PQexec(conn, "CLOSE myportal");
  PQclear(res);

  /* end the transaction */
  res = PQexec(conn, "END");
  PQclear(res);

  /* close the connection to the database and cleanup */
  PQfinish(conn);

  return convertIntToML(0);
}
