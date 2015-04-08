import DataFrames

function test_dataframes()
    df = connect(Postgres, "localhost", "postgres") do conn
        stmt = prepare(conn, "SELECT 4::integer as foo, 4.0::DOUBLE PRECISION as bar, " *
            "NULL::integer as foobar;")
        result = execute(stmt)
        return fetchdf(result)
    end

    @test isa(df, DataFrames.DataFrame)
    @test df[:foo] == Int32[4]
    @test df[:bar] == Float64[4.0]
    @test isna(df[:foobar][1])

    df2 = connect(Postgres, "localhost", "postgres") do conn
        run(conn, """CREATE TEMPORARY TABLE dftable (foo integer, bar double precision,
            foobar integer);""")
        testdberror(conn, PostgreSQL.CONNECTION_OK)
        # stmt = prepare(conn, "INSERT INTO dftable (foo, bar, foobar) VALUES (\$1, \$2, \$3);")
        run(conn, "INSERT INTO dftable (foo, bar, foobar) VALUES (4, 4.0, NULL);")
        testdberror(conn, PostgreSQL.CONNECTION_OK)
        # executemany(stmt, Vector[{4, 4.0, 4}])
        # testdberror(stmt, PostgreSQL.PGRES_COMMAND_OK)
        stmt = prepare(conn, "SELECT * FROM dftable;")
        result = execute(stmt)
        return fetchdf(result)
    end

    @test names(df) == names(df2)
    for col in names(df)
        @test all(isna(df[col]) == isna(df2[col]))
        @test all([(isna(df[col][i]) && isna(df2[col][i])) || (df[col][i] == df2[col][i])
            for i in 1:length(df[col])])
    end
end

test_dataframes()
