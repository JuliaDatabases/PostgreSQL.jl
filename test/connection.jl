function test_connection()
    libpq = PostgreSQL.libpq

    conn = connect(Postgres, "localhost", "postgres")
    @test isa(conn, PostgreSQL.PostgresDatabaseHandle)
    @test conn.status == PostgreSQL.CONNECTION_OK
    @test bytestring(libpq.PQdb(conn.ptr)) == "postgres"
    @test bytestring(libpq.PQuser(conn.ptr)) == "postgres"
    @test bytestring(libpq.PQport(conn.ptr)) == "5432"
    
    disconnect(conn)
    @test conn.closed
end

test_connection()
