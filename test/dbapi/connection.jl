facts("Test dbapi connection") do
    conn = connect(PostgreSQL.PostgreSQLDBAPI.PostgreSQLInterface;
        host="localhost",
        user="postgres",
        dbname="julia_test",
    )

    @fact isa(conn, PostgreSQL.PostgreSQLDBAPI.Connections.PostgreSQLConnection) --> true
    @fact isa(conn, DBAPI.DatabaseConnection) --> true
end
