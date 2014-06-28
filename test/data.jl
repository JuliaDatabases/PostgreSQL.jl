function testdata()
    PostgresType = PostgreSQL.PostgresType
    values = {int16(4), int32(4), int64(4), float32(4), float64(4)}

    types = {PostgresType{:int2}, PostgresType{:int4}, PostgresType{:int8},
        PostgresType{:float4}, PostgresType{:float8}}

    p = convert(Ptr{Uint8}, c_malloc(8))
    try
        for i = 1:length(values)
            p = PostgreSQL.storestring!(p, string(values[i]))
            data = PostgreSQL.jldata(types[i], p)
            testsameness(data, values[i])
        end
    finally
        c_free(p)
    end

    str = "foobar"
    data = PostgreSQL.jldata(PostgresType{:varchar}, convert(Ptr{Uint8}, str))
    @test typeof(str) == typeof(data)
    @test str == data

    str = "fooba\u211D"
    data = PostgreSQL.jldata(PostgresType{:varchar}, convert(Ptr{Uint8}, str))
    @test typeof(str) == typeof(data)
    @test str == data

    p = c_malloc(8)
    try
        for i = 1:length(values)
            p = PostgreSQL.pgdata(types[i], convert(Ptr{Uint8}, p), values[i])
            data = PostgreSQL.jldata(types[i], p)
            testsameness(data, values[i])
        end
    finally
        c_free(p)
    end
end

testdata()
