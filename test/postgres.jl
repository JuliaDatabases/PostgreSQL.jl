function testpostgres()
    PostgresType = PostgreSQL.PostgresType
    conn = connect(Postgres, "localhost", "postgres")
    run(conn, """CREATE TEMPORARY TABLE foobar (foo INTEGER PRIMARY KEY, bar DOUBLE PRECISION, 
        foobar CHARACTER VARYING);""")
    stmt = prepare(conn, "INSERT INTO foobar (foo, bar, foobar) VALUES (\$1, \$2, \$3);")
    @test isempty(stmt.paramtypes)  # now that prepared statements are not being created
end

testpostgres()
