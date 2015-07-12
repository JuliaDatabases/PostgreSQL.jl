function test_numerics()
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

function test_strings()
    PGType = PostgreSQL.PostgresType
    for typ in {PGType{:varchar}, PGType{:text}, PGType{:bpchar}}
        for str in {"foobar", "fooba\u211D"}
            p = PostgreSQL.pgdata(typ, convert(Ptr{Uint8}, C_NULL), str)
            try
                data = PostgreSQL.jldata(typ, p)
                @test typeof(str) == typeof(data)
                @test str == data
            finally
                c_free(p)
            end
        end
    end
end

function test_bytea()
    typ = PostgreSQL.PostgresType{:bytea}
    bin = (Uint8)[0x01, 0x03, 0x42, 0xab, 0xff]
    p = PostgreSQL.pgdata(typ, convert(Ptr{Uint8}, C_NULL), bin)
    try
        data = PostgreSQL.jldata(typ, p)
        @test typeof(bin) == typeof(data)
        @test bin == data
    finally
        c_free(p)
    end
end

function test_json()
    PGType = PostgreSQL.PostgresType
    for typ in {PGType{:json}, PGType{:jsonb}}
        dict1 = Dict{String,Any}({"bobr dobr" => [1, 2, 3]})
        p = PostgreSQL.pgdata(typ, convert(Ptr{Uint8}, C_NULL), dict1)
        try
            dict2 = PostgreSQL.jldata(typ, p)
            @test typeof(dict1) == typeof(dict2)
            @test dict1 == dict2
        finally
            c_free(p)
        end
    end
end

test_numerics()
test_strings()
test_bytea()
test_json()
