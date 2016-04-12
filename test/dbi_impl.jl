import DataFrames: DataFrameRow
import DataArrays: NA
import Compat: @compat, parse

function test_dbi()
    @test Postgres <: DBI.DatabaseSystem

    conn = connect(Postgres, "localhost", "postgres", "", "julia_test")

    @test isa(conn, DBI.DatabaseHandle)
    @test isdefined(conn, :status)

    stmt = prepare(conn, "SELECT 1::bigint, 2.0::double precision, 'foo'::character varying, " *
                         "'foo'::character(10), NULL;")
    result = execute(stmt)
    testdberror(result, PostgreSQL.PGRES_TUPLES_OK)

    iterresults = Vector{Any}[]
    for row in result
        @test row[1] === @compat Int64(1)
        @test_approx_eq row[2] 2.0
        @test typeof(row[2]) == Float64
        @test row[3] == "foo"
        @test typeof(row[3]) <: AbstractString
        @test row[4] == "foo       "
        @test typeof(row[4]) <: AbstractString
        @test row[5] === Union{}
        push!(iterresults, row)
    end

    allresults = fetchall(result)

    @test iterresults == allresults

    dfresults = fetchdf(result)

    dfrow = Any[x[2] for x in DataFrameRow(dfresults, 1)]
    dfrow[5] = Union{}

    @test dfrow == allresults[1]

    finish(stmt)


    create_str = """CREATE TEMPORARY TABLE testdbi (
            id serial PRIMARY KEY,
            combo double precision,
            quant double precision,
            name varchar,
            color text,
            bin bytea,
            is_planet bool,
            num_int numeric(80,0),
            num_float numeric(80,10)
        );"""

    run(conn, create_str)

    data = Vector[
        Any[1, 4, "Spam spam eggs and spam", "red", (UInt8)[0x01, 0x02, 0x03, 0x04], Union{}, BigInt(123), parse(BigFloat, "123.4567")],
        Any[5, 8, "Michael Spam Palin", "blue", (UInt8)[], true, -3, parse(BigFloat, "-3.141592653")],
        Any[3, 16, Union{}, Union{}, Union{}, false, Union{}, Union{}],
        Any[NA, 32, "Foo", "green", (UInt8)[0xfe, 0xdc, 0xba, 0x98, 0x76], true, 9876, parse(BigFloat, "9876.54321")]
    ]

    insert_str = "INSERT INTO testdbi (combo, quant, name, color, bin, is_planet, num_int, num_float) " *
                 "VALUES(\$1, \$2, \$3, \$4, \$5, \$6, \$7, \$8);"

    stmt = prepare(conn, insert_str)
    for row in data
        execute(stmt, row)
        testdberror(stmt, PostgreSQL.PGRES_COMMAND_OK)
    end
    finish(stmt)

    stmt = prepare(conn, "SELECT combo, quant, name, color, bin, is_planet, num_int, num_float FROM testdbi ORDER BY id;")
    result = execute(stmt)
    testdberror(stmt, PostgreSQL.PGRES_TUPLES_OK)
    rows = fetchall(result)
    @test rows[1] == data[1]
    @test rows[2] == data[2]
    @test rows[3] == data[3]
    @test rows[4][1] == Union{}
    @test rows[4][2] == data[4][2]
    @test rows[4][3] == data[4][3]
    @test rows[4][4] == data[4][4]
    @test rows[4][5] == data[4][5]
    @test rows[4][6] == data[4][6]
    @test rows[4][7] == data[4][7]
    @test rows[4][8] == data[4][8]

    finish(stmt)

    disconnect(conn)

    conn = connect(Postgres, "localhost", "postgres", "", "julia_test")
    run(conn, create_str)
    stmt = prepare(conn, insert_str)
    executemany(stmt, data)
    testdberror(stmt, PostgreSQL.PGRES_COMMAND_OK)
    finish(stmt)

    stmt = prepare(conn, "SELECT combo, quant, name, color, bin, is_planet, num_int, num_float FROM testdbi ORDER BY id;")
    result = execute(stmt)
    testdberror(stmt, PostgreSQL.PGRES_TUPLES_OK)
    rows = fetchall(result)
    @test rows[1] == data[1]
    @test rows[2] == data[2]
    @test rows[3] == data[3]
    @test rows[4][1] == Union{}
    @test rows[4][2] == data[4][2]
    @test rows[4][3] == data[4][3]
    @test rows[4][4] == data[4][4]
    @test rows[4][5] == data[4][5]
    @test rows[4][6] == data[4][6]
    @test rows[4][7] == data[4][7]
    @test rows[4][8] == data[4][8]

    finish(stmt)

    @test escapeliteral(conn, 3) == 3
    @test escapeliteral(conn, 3.3) == 3.3
    @test escapeliteral(conn, "foo") == "'foo'"
    @test escapeliteral(conn, "fo\u2202") == "'fo\u2202'"
    @test escapeliteral(conn, SubString("myfood", 3, 5)) == "'foo'"

    disconnect(conn)

    # Test copy
    conn = connect(Postgres, "localhost", "postgres", "", "julia_test")
    create_str = """CREATE TEMPORARY TABLE testcopycsv(
      intdata INTEGER,
      otherint INTEGER,
      textdata TEXT,
      floatdata DOUBLE PRECISION
    );"""

    run(conn, create_str)
    copy_from(conn, "testcopycsv", "test_data.csv", "csv")

    stmt = prepare(conn, "SELECT * FROM testcopycsv WHERE intdata > 1;")
    rs = execute(stmt)
    rows = fetchall(rs)
    @test rows[1][1] == 2
    @test rows[1][4] == "green"
    @test rows[2][3] == "i'm sick of eggs now"
    testdberror(stmt, PostgreSQL.PGRES_TUPLES_OK)
    finish(stmt)

    disconnect(conn)

    # Test arrays
    conn = connect(Postgres, "localhost", "postgres", "", "julia_test")
    create_str = """CREATE TEMPORARY TABLE testarrays(
      intdata INTEGER,
      floatdata DOUBLE PRECISION,
      textdata TEXT,
      varchardata VARCHAR
    );"""

    run(conn, create_str)

    data = Vector[
        Any[1, 1.0, "1", "one"],
        Any[2, 2.0, "2", "two"],
        Any[3, 3.0, "3", "three"],
    ]

    insert_str = "INSERT INTO testarrays(intdata, floatdata, textdata, varchardata) " *
                 "VALUES(\$1, \$2, \$3, \$4);"

    stmt = prepare(conn, insert_str)
    for row in data
        execute(stmt, row)
        testdberror(stmt, PostgreSQL.PGRES_COMMAND_OK)
    end
    finish(stmt)

    stmt = prepare(conn, "SELECT * FROM testarrays WHERE textdata = ANY(\$1);")
    rs = execute(stmt, Any[["1", "2"]])
    for (i, row) in enumerate(rs)
      @test row[1] == data[i][1]
      @test row[2] == data[i][2]
      @test row[3] == data[i][3]
      @test row[4] == data[i][4]
    end
    testdberror(stmt, PostgreSQL.PGRES_TUPLES_OK)
    finish(stmt)

    stmt = prepare(conn, "SELECT * FROM testarrays WHERE textdata = ANY(\$1::varchar[]);")
    rs = execute(stmt, Any[["one", "two"]])
    for (i, row) in enumerate(rs)
      @test row[1] == data[i][1]
      @test row[2] == data[i][2]
      @test row[3] == data[i][3]
      @test row[4] == data[i][4]
    end
    testdberror(stmt, PostgreSQL.PGRES_TUPLES_OK)
    finish(stmt)

    stmt = prepare(conn, "SELECT * FROM testarrays WHERE intdata = ANY(\$1);")
    rs = execute(stmt, Any[[1, 2]])
    for (i, row) in enumerate(rs)
      @test row[1] == data[i][1]
      @test row[2] == data[i][2]
      @test row[3] == data[i][3]
      @test row[4] == data[i][4]
    end
    testdberror(stmt, PostgreSQL.PGRES_TUPLES_OK)
    finish(stmt)

    stmt = prepare(conn, "SELECT * FROM testarrays WHERE floatdata = ANY(\$1);")
    rs = execute(stmt, Any[[1.0, 2.0]])
    for (i, row) in enumerate(rs)
      @test row[1] == data[i][1]
      @test row[2] == data[i][2]
      @test row[3] == data[i][3]
      @test row[4] == data[i][4]
    end
    testdberror(stmt, PostgreSQL.PGRES_TUPLES_OK)
    finish(stmt)

    stmt = prepare(conn, """
    SELECT 
    '{1,2}'::integer[], 
    '{1.0,2.0}'::double precision[], 
    '{"aaa", "bbb"}'::text[],
    '{"aaa", "bbb"}'::varchar[];
    """)
    rs = execute(stmt)
    for row in rs
      @test row[1] == [1,2]
      @test row[2] == [1.0,2.0]
      @test row[3] == ["aaa","bbb"]
      @test row[4] == ["aaa","bbb"]
    end
    testdberror(stmt, PostgreSQL.PGRES_TUPLES_OK)
    finish(stmt)

    disconnect(conn)
end

test_dbi()
