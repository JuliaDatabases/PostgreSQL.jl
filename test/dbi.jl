function test_dbi()
    @test Postgres <: DBI.DatabaseSystem

    conn = connect(Postgres, "localhost", "postgres")
    
    @test isa(conn, DBI.DatabaseHandle)
    @test isdefined(conn, :status)

    disconnect(conn)
end

test_dbi()
