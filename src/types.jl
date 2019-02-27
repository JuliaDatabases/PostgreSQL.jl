import DataArrays: NAtype
import JSON
import Compat: Libc, unsafe_convert, parse, @compat

abstract AbstractPostgresType
type PostgresType{Name} <: AbstractPostgresType end

abstract AbstractOID
type OID{N} <: AbstractOID end

oid{T<:AbstractPostgresType}(t::Type{T}) = convert(OID, t)
pgtype(t::Type) = convert(PostgresType, t)

Base.convert{T}(::Type{Oid}, ::Type{OID{T}}) = convert(Oid, T)

function newpgtype(pgtypename, oid, jltypes)
    Base.convert(::Type{OID}, ::Type{PostgresType{pgtypename}}) = OID{oid}
    Base.convert(::Type{PostgresType}, ::Type{OID{oid}}) = PostgresType{pgtypename}

    for t in jltypes
        Base.convert(::Type{PostgresType}, ::Type{t}) = PostgresType{pgtypename}
    end
end

# To check oids in postgres, use this SQL query on a psql prompt:
#   select typname, typarray, oid from pg_type;
##
newpgtype(:bool, 16, (Bool,))
newpgtype(:bytea, 17, (Vector{UInt8},))
newpgtype(:int8, 20, (Int64,))
newpgtype(:int4, 23, (Int32,))
newpgtype(:int2, 21, (Int16,))
newpgtype(:float8, 701, (Float64,))
newpgtype(:float4, 700, (Float32,))
newpgtype(:bpchar, 1042, ())
newpgtype(:varchar, 1043, (String,String))
newpgtype(:text, 25, ())
newpgtype(:numeric, 1700, (BigInt,BigFloat))
newpgtype(:date, 1082, ())
newpgtype(:timestamp, 1114, ())
newpgtype(:timestamptz, 1184, ())
newpgtype(:unknown, 705, (Union,NAtype))
newpgtype(:json, 114, (Dict{AbstractString,Any},))
newpgtype(:jsonb, 3802, (Dict{AbstractString,Any},))

# Support for Postgres array types, underscore indicates array
newpgtype(:_bool, 1000, (Vector{Bool},))
newpgtype(:_int8, 1016, (Vector{Int64},))
newpgtype(:_int4, 1007, (Vector{Int32},))
newpgtype(:_int2, 1005, (Vector{Int16},))
newpgtype(:_float8, 1022, (Vector{Float64},))
newpgtype(:_float4, 1021, (Vector{Float32},))
newpgtype(:_varchar, 1015, (Vector{String}, Vector{String}))
newpgtype(:_text, 1009, (Vector{String}, Vector{String}))


typealias PGStringTypes Union{Type{PostgresType{:bpchar}},
                              Type{PostgresType{:varchar}},
                              Type{PostgresType{:text}},
                              Type{PostgresType{:date}}}

function storestring!(ptr::Ptr{UInt8}, str::AbstractString)
    ptr = convert(Ptr{UInt8}, Libc.realloc(ptr, sizeof(str)+1))
    unsafe_copy!(ptr, unsafe_convert(Ptr{UInt8}, str), sizeof(str)+1)
    return ptr
end

# In text mode, pq returns bytea as a text string "\xAABBCCDD...", for instance
# UInt8[0x01, 0x23, 0x45] would come in as "\x012345"
function decode_bytea_hex(s::AbstractString)
    if length(s) < 2 || s[1] != '\\' || s[2] != 'x'
        error("Malformed bytea string: $s")
    end
    return hex2bytes(s[3:end])
end

jldata(::Type{PostgresType{:date}}, ptr::Ptr{UInt8}) = bytestring(ptr)

jldata(::Type{PostgresType{:timestamp}}, ptr::Ptr{UInt8}) = bytestring(ptr)

jldata(::Type{PostgresType{:timestamptz}}, ptr::Ptr{UInt8}) = bytestring(ptr)

jldata(::Type{PostgresType{:bool}}, ptr::Ptr{UInt8}) = bytestring(ptr) != "f"

jldata(::Type{PostgresType{:int8}}, ptr::Ptr{UInt8}) = parse(Int64, bytestring(ptr))

jldata(::Type{PostgresType{:int4}}, ptr::Ptr{UInt8}) = parse(Int32, bytestring(ptr))

jldata(::Type{PostgresType{:int2}}, ptr::Ptr{UInt8}) = parse(Int16, bytestring(ptr))

jldata(::Type{PostgresType{:float8}}, ptr::Ptr{UInt8}) = parse(Float64, bytestring(ptr))

jldata(::Type{PostgresType{:float4}}, ptr::Ptr{UInt8}) = parse(Float32, bytestring(ptr))

function jldata(::Type{PostgresType{:numeric}}, ptr::Ptr{UInt8})
    s = bytestring(ptr)
    return parse(search(s, '.') == 0 ? BigInt : BigFloat, s)
end

jldata(::PGStringTypes, ptr::Ptr{UInt8}) = bytestring(ptr)

jldata(::Type{PostgresType{:bytea}}, ptr::Ptr{UInt8}) = bytestring(ptr) |> decode_bytea_hex

jldata(::Type{PostgresType{:unknown}}, ptr::Ptr{UInt8}) = Union{}

jldata(::Type{PostgresType{:json}}, ptr::Ptr{UInt8}) = JSON.parse(bytestring(ptr))

jldata(::Type{PostgresType{:jsonb}}, ptr::Ptr{UInt8}) = JSON.parse(bytestring(ptr))

jldata(::Type{PostgresType{:_bool}}, ptr::Ptr{UInt8}) = map(x -> x != "f", split(bytestring(ptr)[2:end-1], ','))

jldata(::Type{PostgresType{:_int8}}, ptr::Ptr{UInt8}) = map(x -> parse(Int64, x), split(bytestring(ptr)[2:end-1], ','))

jldata(::Type{PostgresType{:_int4}}, ptr::Ptr{UInt8}) = map(x -> parse(Int32, x), split(bytestring(ptr)[2:end-1], ','))

jldata(::Type{PostgresType{:_int2}}, ptr::Ptr{UInt8}) = map(x -> parse(Int16, x), split(bytestring(ptr)[2:end-1], ','))

jldata(::Type{PostgresType{:_float8}}, ptr::Ptr{UInt8}) = map(x -> parse(Float64, x), split(bytestring(ptr)[2:end-1], ','))

jldata(::Type{PostgresType{:_float4}}, ptr::Ptr{UInt8}) = map(x -> parse(Float32, x), split(bytestring(ptr)[2:end-1], ','))

jldata(::Type{PostgresType{:_varchar}}, ptr::Ptr{UInt8}) = convert(Vector{AbstractString}, split(bytestring(ptr)[2:end-1], ','))

jldata(::Type{PostgresType{:_text}}, ptr::Ptr{UInt8}) = convert(Vector{AbstractString}, split(bytestring(ptr)[2:end-1], ','))

function pgdata(::Type{PostgresType{:bool}}, ptr::Ptr{UInt8}, data::Bool)
    ptr = data ? storestring!(ptr, "TRUE") : storestring!(ptr, "FALSE")
end

function pgdata(::Type{PostgresType{:int8}}, ptr::Ptr{UInt8}, data::Number)
    ptr = storestring!(ptr, string(convert(Int64, data)))
end

function pgdata(::Type{PostgresType{:int4}}, ptr::Ptr{UInt8}, data::Number)
    ptr = storestring!(ptr, string(convert(Int32, data)))
end

function pgdata(::Type{PostgresType{:int2}}, ptr::Ptr{UInt8}, data::Number)
    ptr = storestring!(ptr, string(convert(Int16, data)))
end

function pgdata(::Type{PostgresType{:float8}}, ptr::Ptr{UInt8}, data::Number)
    ptr = storestring!(ptr, string(convert(Float64, data)))
end

function pgdata(::Type{PostgresType{:float4}}, ptr::Ptr{UInt8}, data::Number)
    ptr = storestring!(ptr, string(convert(Float32, data)))
end

function pgdata(::Type{PostgresType{:numeric}}, ptr::Ptr{UInt8}, data::Number)
    ptr = storestring!(ptr, string(data))
end

function pgdata(::PGStringTypes, ptr::Ptr{UInt8}, data::AbstractString)
    ptr = storestring!(ptr, bytestring(data))
end

function pgdata(::PostgresType{:date}, ptr::Ptr{UInt8}, data::AbstractString)
    ptr = storestring!(ptr, bytestring(data))
    ptr = Dates.DateFormat(ptr)
end

function pgdata(::PostgresType{:timestamp}, ptr::Ptr{UInt8}, data::AbstractString)
    ptr = storestring!(ptr, bytestring(data))
end

function pgdata(::PostgresType{:timestamptz}, ptr::Ptr{UInt8}, data::AbstractString)
    ptr = storestring!(ptr, bytestring(data))
end

function pgdata(::Type{PostgresType{:bytea}}, ptr::Ptr{UInt8}, data::Vector{UInt8})
    ptr = storestring!(ptr, bytestring("\\x", bytes2hex(data)))
end

function pgdata(::Type{PostgresType{:unknown}}, ptr::Ptr{UInt8}, data)
    ptr = storestring!(ptr, string(data))
end

function pgdata{T<:AbstractString}(::Type{PostgresType{:json}}, ptr::Ptr{UInt8}, data::Dict{T,Any})
    ptr = storestring!(ptr, bytestring(JSON.json(data)))
end

function pgdata{T<:AbstractString}(::Type{PostgresType{:jsonb}}, ptr::Ptr{UInt8}, data::Dict{T,Any})
    ptr = storestring!(ptr, bytestring(JSON.json(data)))
end

function pgdata(::Type{PostgresType{:_bool}}, ptr::Ptr{UInt8}, data::Vector{Bool})
    ptr = storestring!(ptr, string("{", join(map(x -> x ? "t" : "f", data), ','), "}"))
end

function pgdata(::Type{PostgresType{:_int8}}, ptr::Ptr{UInt8}, data::Vector{Int64})
    ptr = storestring!(ptr, string("{", join(data, ','), "}"))
end

function pgdata(::Type{PostgresType{:_int4}}, ptr::Ptr{UInt8}, data::Vector{Int32})
    ptr = storestring!(ptr, string("{", join(data, ','), "}"))
end

function pgdata(::Type{PostgresType{:_int2}}, ptr::Ptr{UInt8}, data::Vector{Int16})
    ptr = storestring!(ptr, string("{", join(data, ','), "}"))
end

function pgdata(::Type{PostgresType{:_float8}}, ptr::Ptr{UInt8}, data::Vector{Float64})
    ptr = storestring!(ptr, string("{", join(data, ','), "}"))
end

function pgdata(::Type{PostgresType{:_float4}}, ptr::Ptr{UInt8}, data::Vector{Float64})
    ptr = storestring!(ptr, string("{", join(data, ','), "}"))
end

function pgdata(::Type{PostgresType{:_varchar}}, ptr::Ptr{UInt8}, data::Vector{String})
    ptr = storestring!(ptr, string("{", join(data, ','), "}"))
end

function pgdata(::Type{PostgresType{:_text}}, ptr::Ptr{UInt8}, data::Vector{String})
    ptr = storestring!(ptr, string("{", join(data, ','), "}"))
end

# dbi
abstract Postgres <: DBI.DatabaseSystem

type PostgresDatabaseHandle <: DBI.DatabaseHandle
    ptr::Ptr{PGconn}
    status::ConnStatusType
    closed::Bool

    function PostgresDatabaseHandle(ptr::Ptr{PGconn}, status::ConnStatusType)
        new(ptr, status, false)
    end
end

type PostgresResultHandle
    ptr::Ptr{PGresult}
    types::Vector{DataType}
    nrows::Integer
    ncols::Integer
end

function PostgresResultHandle(result::Ptr{PGresult})
    status = PQresultStatus(result)
    if status == PGRES_TUPLES_OK || status == PGRES_SINGLE_TUPLE
        oids = @compat [OID{Int(PQftype(result, col))} for col in 0:(PQnfields(result)-1)]
        types = DataType[convert(PostgresType, x) for x in oids]
    else
        types = DataType[]
    end
    return PostgresResultHandle(result, types, PQntuples(result), PQnfields(result))
end

type PostgresStatementHandle <: DBI.StatementHandle
    db::PostgresDatabaseHandle
    stmt::AbstractString
    executed::Int
    paramtypes::Array{DataType}
    finished::Bool
    result::PostgresResultHandle

    function PostgresStatementHandle(db::PostgresDatabaseHandle, stmt::AbstractString, executed=0, paramtypes::Array{DataType}=DataType[])
        new(db, stmt, executed, paramtypes, false)
    end
end

function Base.copy(rh::PostgresResultHandle)
    PostgresResultHandle(PQcopyResult(result, PG_COPYRES_ATTRS | PG_COPYRES_TUPLES |
        PG_COPYRES_NOTICEHOOKS | PG_COPYRES_EVENTS), copy(rh.types), rh.ntuples, rh.nfields)
end

