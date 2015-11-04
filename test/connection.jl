facts("Test connection") do
    libpq = PostgreSQL.libpq_interface

    context("Basic connect") do
        conn = connect(Postgres, "localhost", "postgres", "", "julia_test")
        @fact isa(conn, PostgreSQL.PostgresDatabaseHandle) --> true
        @fact conn.status --> PostgreSQL.CONNECTION_OK
        @fact errcode(conn) --> PostgreSQL.CONNECTION_OK
        @fact conn.closed --> false
        @fact bytestring(libpq.PQdb(conn.ptr)) --> "julia_test"
        @fact bytestring(libpq.PQuser(conn.ptr)) --> "postgres"
        @fact bytestring(libpq.PQport(conn.ptr)) --> "5432"

        disconnect(conn)
        @fact conn.closed --> true
    end

    context("Do block") do
        conn = connect(Postgres, "localhost", "postgres", "", "julia_test") do conn
            @fact isa(conn, PostgreSQL.PostgresDatabaseHandle) --> true
            @fact conn.status --> PostgreSQL.CONNECTION_OK
            @fact errcode(conn) --> PostgreSQL.CONNECTION_OK
            @fact conn.closed --> false
            return conn
        end
        @fact conn.closed --> true
    end

    context("Connection with DSN string") do
        conn = connect(Postgres; dsn="postgresql://postgres@localhost:5432/julia_test")
        @fact isa(conn, PostgreSQL.PostgresDatabaseHandle) --> true
        @fact conn.status --> PostgreSQL.CONNECTION_OK
        @fact errcode(conn) --> PostgreSQL.CONNECTION_OK
        @fact conn.closed --> false
        @fact bytestring(libpq.PQdb(conn.ptr)) --> "julia_test"
        @fact bytestring(libpq.PQuser(conn.ptr)) --> "postgres"
        @fact bytestring(libpq.PQport(conn.ptr)) --> "5432"

        disconnect(conn)
        @fact conn.closed --> true
    end

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
