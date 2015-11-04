import DataFrames
import DataArrays: isna

facts("Dataframes") do
    df = connect(Postgres, "localhost", "postgres", "", "julia_test") do conn
        stmt = prepare(conn, "SELECT 4::integer as foo, 4.0::DOUBLE PRECISION as bar, " *
            "NULL::integer as foobar;")
        result = execute(stmt)
        return fetchdf(result)
    end

    @fact isa(df, DataFrames.DataFrame) --> true
    @fact df[:foo] --> Int32[4]
    @fact df[:bar] --> Float64[4.0]
    @fact isna(df[:foobar][1]) --> true

    df2 = connect(Postgres, "localhost", "postgres", "", "julia_test") do conn
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

    @fact names(df) --> names(df2)
    for col in names(df)
        for (dfel, df2el) in zip(df[col], df2[col])
            @fact isna(dfel) --> isna(df2el)

            if !isna(dfel) && !isna(df2el)
                @fact dfel --> df2el
            end
        end
    end
end
