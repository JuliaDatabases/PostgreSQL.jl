
import DBInterface, PostgreSQL, DataFrames, LibPQ
using Test

@testset "PostgreSQL.jl" begin
    db_name = "postgres"
    user = "postgres"
    port = 5432
    host = "localhost"
    password = "pass"

    conn = DBInterface.connect(PostgreSQL.Connection, "dbname=$db_name user=$user port=$port host=$host password=$password")
    @test typeof(conn) <: PostgreSQL.Connection

    stmt = DBInterface.prepare(conn, "CREATE DATABASE test;")
    @test typeof(stmt) <: PostgreSQL.Stmt

    result = DBInterface.execute(stmt)
    @test LibPQ.status(result) == LibPQ.libpq_c.PGRES_COMMAND_OK

    DBInterface.close!(conn)
    @test !LibPQ.isopen(conn.inner)
    @test conn.inner.closed[] == true

    conn = DBInterface.connect(PostgreSQL.Connection, "dbname=test user=$user port=$port host=$host password=$password")

    sql = """
    CREATE TABLE Persons(
        id              SERIAL,
        name            TEXT NOT NULL,
        PRIMARY KEY (id)
    );
    """
    stmt = DBInterface.prepare(conn, sql)
    result = DBInterface.execute(stmt)
    @test LibPQ.status(result) == LibPQ.libpq_c.PGRES_COMMAND_OK

    stmt = DBInterface.prepare(conn, "INSERT INTO Persons(name) VALUES(?);")
    result = DBInterface.execute(stmt, ["adam"])
    @test LibPQ.status(result) == LibPQ.libpq_c.PGRES_COMMAND_OK

    stmt = DBInterface.prepare(conn, "INSERT INTO Persons(name) VALUES(:name);")
    result = DBInterface.execute(stmt, ("maria",))
    @test LibPQ.status(result) == LibPQ.libpq_c.PGRES_COMMAND_OK

    result = DBInterface.executemany(stmt, (name = ["eva", "paul"],))
    @test LibPQ.status(result) == LibPQ.libpq_c.PGRES_COMMAND_OK

    df = DBInterface.execute(conn, "SELECT * from Persons;") |> DataFrames.DataFrame
    @test df.name == ["adam", "maria", "eva", "paul"]

    DBInterface.close!(conn)
end