import Compat: unsafe_string

function test_connection()
  println("Using libpq")
    libpq = PostgreSQL.libpq_interface

    println("Checking basic connect")
    conn = connect(Postgres, "localhost", "postgres", "", "julia_test")
    @test isa(conn, PostgreSQL.PostgresDatabaseHandle)
    @test conn.status == PostgreSQL.CONNECTION_OK
    @test errcode(conn) == PostgreSQL.CONNECTION_OK
    @test !conn.closed
    @test unsafe_string(libpq.PQdb(conn.ptr)) == "julia_test"
    @test unsafe_string(libpq.PQuser(conn.ptr)) == "postgres"
    @test unsafe_string(libpq.PQport(conn.ptr)) == "5432"

    disconnect(conn)
    @test conn.closed
    println("Basic connection passed")

    println("Checking doblock")
    conn = connect(Postgres, "localhost", "postgres", "", "julia_test") do conn
        @test isa(conn, PostgreSQL.PostgresDatabaseHandle)
        @test conn.status == PostgreSQL.CONNECTION_OK
        @test errcode(conn) == PostgreSQL.CONNECTION_OK
        @test !conn.closed
        return conn
    end
    @test conn.closed
    println("Doblock passed")

    println("Testing connection with DSN string")
    conn = connect(Postgres; dsn="postgresql://postgres@localhost:5432/julia_test")
    @test isa(conn, PostgreSQL.PostgresDatabaseHandle)
    @test conn.status == PostgreSQL.CONNECTION_OK
    @test errcode(conn) == PostgreSQL.CONNECTION_OK
    @test !conn.closed
    @test unsafe_string(libpq.PQdb(conn.ptr)) == "julia_test"
    @test unsafe_string(libpq.PQuser(conn.ptr)) == "postgres"
    @test unsafe_string(libpq.PQport(conn.ptr)) == "5432"

    disconnect(conn)
    @test conn.closed
    println("DSN connection passed")

#=    println("Testing connection with DSN string and doblock")
    conn = connect(Postgres; dsn="postgresql://postgres@localhost:5432/postgres") do conn
        @test isa(conn, PostgreSQL.PostgresDatabaseHandle)
        @test conn.status == PostgreSQL.CONNECTION_OK
        @test errcode(conn) == PostgreSQL.CONNECTION_OK
        @test !conn.closed
        return conn
    end
    @test conn.closed
    println("DSN connection passed in a do block")=#
end

test_connection()
