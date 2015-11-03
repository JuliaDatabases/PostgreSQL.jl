function test_dbapi_connection()
    conn = connect(PostgreSQL.PostgreSQLDBAPI.PostgreSQLInterface;
        host="localhost",
        user="postgres",
        dbname="julia_test",
    )
end

test_dbapi_connection()
