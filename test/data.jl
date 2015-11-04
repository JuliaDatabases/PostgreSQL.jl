import Compat: Libc, @compat

facts("Data type conversions") do
    context("Numerics") do
        PostgresType = PostgreSQL.PostgresType
        values = @compat Any[Int16(4), Int32(4), Int64(4), Float32(4), Float64(4)]

        types = [PostgresType{:int2}, PostgresType{:int4}, PostgresType{:int8},
            PostgresType{:float4}, PostgresType{:float8}]

        p = convert(Ptr{UInt8}, Libc.malloc(8))
        try
            for i = 1:length(values)
                p = PostgreSQL.storestring!(p, string(values[i]))
                data = PostgreSQL.jldata(types[i], p)
                @fact is(data, values[i]) --> true
            end
        finally
            Libc.free(p)
        end

        p = Libc.malloc(8)
        try
            for i = 1:length(values)
                p = PostgreSQL.pgdata(types[i], convert(Ptr{UInt8}, p), values[i])
                data = PostgreSQL.jldata(types[i], p)
                @fact is(data, values[i]) --> true
            end
        finally
            Libc.free(p)
        end
    end

    context("Strings") do
        PGType = PostgreSQL.PostgresType
        for typ in [PGType{:varchar}, PGType{:text}, PGType{:bpchar}]
            for str in Any["foobar", "fooba\u211D"]
                p = PostgreSQL.pgdata(typ, convert(Ptr{UInt8}, C_NULL), str)
                try
                    data = PostgreSQL.jldata(typ, p)
                    @fact typeof(str) --> typeof(data)
                    @fact str --> data
                finally
                    Libc.free(p)
                end
            end
        end
    end

    context("Bytes") do
        typ = PostgreSQL.PostgresType{:bytea}
        bin = (UInt8)[0x01, 0x03, 0x42, 0xab, 0xff]
        p = PostgreSQL.pgdata(typ, convert(Ptr{UInt8}, C_NULL), bin)
        try
            data = PostgreSQL.jldata(typ, p)
            @fact typeof(bin) --> typeof(data)
            @fact bin --> data
        finally
            Libc.free(p)
        end
    end

    context("JSON") do
        PGType = PostgreSQL.PostgresType
        for typ in Any[PGType{:json}, PGType{:jsonb}]
            dict1 = @compat Dict{AbstractString,Any}("bobr dobr" => [1, 2, 3])
            p = PostgreSQL.pgdata(typ, convert(Ptr{UInt8}, C_NULL), dict1)
            try
                dict2 = PostgreSQL.jldata(typ, p)
                @fact typeof(dict1) --> typeof(dict2)
                @fact dict1 --> dict2
            finally
                Libc.free(p)
            end
        end
    end
end
