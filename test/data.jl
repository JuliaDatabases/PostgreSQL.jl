import Compat: Libc, @compat

@testset "Data" begin
@testset "Numerics" begin
    PostgresType = PostgreSQL.PostgresType
    values = @compat Any[Int16(4), Int32(4), Int64(4), Float32(4), Float64(4)]

    types = [PostgresType{:int2}, PostgresType{:int4}, PostgresType{:int8},
        PostgresType{:float4}, PostgresType{:float8}]

    p = convert(Ptr{UInt8}, Libc.malloc(8))
    try
        for i = 1:length(values)
            p = PostgreSQL.storestring!(p, string(values[i]))
            data = PostgreSQL.jldata(types[i], p)
            testsameness(data, values[i])
        end
    finally
        Libc.free(p)
    end

    p = Libc.malloc(8)
    try
        for i = 1:length(values)
            p = PostgreSQL.pgdata(types[i], convert(Ptr{UInt8}, p), values[i])
            data = PostgreSQL.jldata(types[i], p)
            testsameness(data, values[i])
        end
    finally
        Libc.free(p)
    end
end

@testset "Strings" begin
    PGType = PostgreSQL.PostgresType
    for typ in [PGType{:varchar}, PGType{:text}, PGType{:bpchar}]
        for str in Any["foobar", "fooba\u211D"]
            p = PostgreSQL.pgdata(typ, convert(Ptr{UInt8}, C_NULL), str)
            try
                data = PostgreSQL.jldata(typ, p)
                @test typeof(str) == typeof(data)
                @test str == data
            finally
                Libc.free(p)
            end
        end
    end
end

@testset "bytea" begin
    typ = PostgreSQL.PostgresType{:bytea}
    bin = (UInt8)[0x01, 0x03, 0x42, 0xab, 0xff]
    p = PostgreSQL.pgdata(typ, convert(Ptr{UInt8}, C_NULL), bin)
    try
        data = PostgreSQL.jldata(typ, p)
        @test typeof(bin) == typeof(data)
        @test bin == data
    finally
        Libc.free(p)
    end
end

@testset "JSON" begin
    PGType = PostgreSQL.PostgresType
    for typ in Any[PGType{:json}, PGType{:jsonb}]
        dict1 = @compat Dict("bobr dobr" => [1, 2, 3], "foo" => 3.0)
        p = PostgreSQL.pgdata(typ, convert(Ptr{UInt8}, C_NULL), dict1)
        try
            dict2 = PostgreSQL.jldata(typ, p)
            @test dict1 == dict2
        finally
            Libc.free(p)
        end
    end
end
