function test_dbi()
    @test Postgres <: DBI.DatabaseSystem

    conn = connect(Postgres, "localhost", "postgres")
    
    @test isa(conn, DBI.DatabaseHandle)
    @test isdefined(conn, :status)

    stmt = prepare(conn, "SELECT 1::bigint, 2.0::double precision, 'foo'::character varying, " *
                         "'foo'::character(10), NULL;")
    result = execute(stmt)
    for row in result
        @test row[1] === int64(1)
        @test_approx_eq row[2] 2.0
        @test typeof(row[2]) == Float64
        @test row[3] == "foo"
        @test typeof(row[3]) <: String
        @test row[4] == "foo       "
        @test typeof(row[4]) <: String
        @test row[5] === None
    end

    finish(stmt)

    disconnect(conn)
end

test_dbi()
