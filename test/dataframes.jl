import DataFrames

function test_dataframes()
    df = connect(Postgres, "localhost", "postgres") do conn
        stmt = prepare(conn, "SELECT 4::integer as foo, 4.0::DOUBLE PRECISION as bar, NULL::integer as foobar;")
        result = execute(stmt)
        return fetchdf(result)
    end

    @test isa(df, DataFrames.DataFrame)
    @test df["foo"] == Int32[4]
    @test df["bar"] == Float64[4.0]
    @test isna(df["foobar"][1])
end

test_dataframes()
