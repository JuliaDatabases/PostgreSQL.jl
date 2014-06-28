function testdata()
    PostgresType = PostgreSQL.PostgresType
    values = {int16(4), int32(4), int64(4), float32(4), float64(4)}

    types = {PostgresType{:int2}, PostgresType{:int4}, PostgresType{:int8},
        PostgresType{:float4}, PostgresType{:float8}}

    p = c_malloc(8)
    try
        for i = 1:length(values)
            unsafe_store!(convert(Ptr{typeof(values[i])}, p), hton(values[i]), 1)
            data = PostgreSQL.jldata(types[i], convert(Ptr{Uint8}, p), -1)
            testsameness(data, values[i])
        end
    finally
        c_free(p)
    end
    
    string = "foobar"
    data = PostgreSQL.jldata(PostgresType{:varchar}, convert(Ptr{Uint8}, string), sizeof(string))
    @test typeof(string) == typeof(data)
    @test string == data

    string = "fooba\u211D"
    data = PostgreSQL.jldata(PostgresType{:varchar}, convert(Ptr{Uint8}, string), sizeof(string))
    @test typeof(string) == typeof(data)
    @test string == data

    p = c_malloc(8)
    try
        for i = 1:length(values)
            p = PostgreSQL.pgdata(types[i], convert(Ptr{Uint8}, p), values[i])
            data = PostgreSQL.jldata(types[i], p, -1)
            testsameness(data, values[i])
        end
    finally
        c_free(p)
    end
end

testdata()
