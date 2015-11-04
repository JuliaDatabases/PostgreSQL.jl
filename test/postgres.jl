facts("PostgreSQL") do
    PostgresType = PostgreSQL.PostgresType
    conn = connect(Postgres, "localhost", "postgres", "", "julia_test")
    run(conn, """CREATE TEMPORARY TABLE foobar (foo INTEGER PRIMARY KEY, bar DOUBLE PRECISION,
        foobar CHARACTER VARYING);""")
    stmt = prepare(conn, "INSERT INTO foobar (foo, bar, foobar) VALUES (\$1, \$2, \$3);")
    @fact stmt.paramtypes --> isempty  # now that prepared statements are not being created
end
