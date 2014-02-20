abstract AbstractPostgresType
type PostgresType{Name} <: AbstractPostgresType end

abstract AbstractOID
type OID{N} <: AbstractOID end

oid{T<:AbstractPostgresType}(t::Type{T}) = convert(OID, t)
pgtype{T<:AbstractOID}(t::Type{T}) = convert(PostgresType, t)

macro pgtype(pgtypename, oid, length)
    quote
        $(esc(:(Base.convert)))(::Type{OID}, ::Type{PostgresType{$pgtypename}}) = OID{$oid}
        $(esc(:(Base.convert)))(::Type{PostgresType}, ::Type{OID{$oid}}) = PostgresType{$pgtypename}
        $(esc(:(Base.sizeof)))(::Type{PostgresType{$pgtypename}}) = $length::Integer
    end
end

# macro pgtypeproxy(jltype, jltypeproxy)
#     $(esc(:pgdata))(ptr::Ptr{Uint8}, data::$jltype) = pgdata(ptr, convert($jltypeproxy, data))
# end


# @pgtype PostgresBool 16
# @pgtype PostgresByteArray 17
# @pgtype PostgresInt64 20
# @pgtype PostgresInt32 23
# @pgtype PostgresInt16 21
# @pgtype PostgresFloat64 701
# @pgtype PostgresFloat32 700
# @pgtype PostgresBlankPaddedChar 1042
# @pgtype PostgresVarChar 1043
# @pgtype PostgresUnknown 705

@pgtype :bool 16 1
@pgtype :bytea 17 -1
@pgtype :int8 20 8
@pgtype :int4 23 4
@pgtype :int2 21 2
@pgtype :float8 701 8
@pgtype :float4 700 4
@pgtype :bpchar 1042 -1
@pgtype :varchar 1043 -1
@pgtype :unknown 705 0

function jldata(::Type{PostgresType{:bool}}, ptr::Ptr{Uint8}, length)
    pointer_to_array(convert(Ptr{Bool}, ptr), 0)[1]
end

function jldata(::Type{PostgresType{:int8}}, ptr::Ptr{Uint8}, length)
    ntoh(pointer_to_array(convert(Ptr{Int64}, ptr), (1,))[1])
end

function jldata(::Type{PostgresType{:int4}}, ptr::Ptr{Uint8}, length)
    ntoh(pointer_to_array(convert(Ptr{Int32}, ptr), (1,))[1])
end

function jldata(::Type{PostgresType{:int2}}, ptr::Ptr{Uint8}, length)
    ntoh(pointer_to_array(convert(Ptr{Int16}, ptr), (1,))[1])
end

function jldata(::Type{PostgresType{:float8}}, ptr::Ptr{Uint8}, length)
    ntoh(pointer_to_array(convert(Ptr{Float64}, ptr), (1,))[1])
end

function jldata(::Type{PostgresType{:float4}}, ptr::Ptr{Uint8}, length)
    ntoh(pointer_to_array(convert(Ptr{Float32}, ptr), (1,))[1])
end

function jldata(::Union(Type{PostgresType{:bpchar}}, Type{PostgresType{:varchar}}), ptr::Ptr{Uint8}, length)
    bytestring(ptr)
end

function jldata(::Type{PostgresType{:unknown}}, ptr::Ptr{Uint8}, length)
    None
end

function pgdata(::Type{PostgresType{:bool}}, ptr::Ptr{Uint8}, data::Bool)
    unsafe_store!(ptr, uint8(data), 1)
end

function pgdata(::Type{PostgresType{:int8}}, ptr::Ptr{Uint8}, data::Number)
    unsafe_store!(ptr, convert(Int64, data), 1)
end

function pgdata(::Type{PostgresType{:int4}}, ptr::Ptr{Uint8}, data::Number)
    unsafe_store!(ptr, convert(Int32, data), 1)
end

function pgdata(::Type{PostgresType{:int2}}, ptr::Ptr{Uint8}, data::Number)
    unsafe_store!(ptr, convert(Int16, data), 1)
end

function pgdata(::Type{PostgresType{:float8}}, ptr::Ptr{Uint8}, data::Number)
    unsafe_store!(ptr, convert(Float64, data), 1)
end

function pgdata(::Type{PostgresType{:float4}}, ptr::Ptr{Uint8}, data::Number)
    unsafe_store!(ptr, convert(Float32, data), 1)
end

function pgdata(::Type{PostgresType{:varchar}}, ptr::Ptr{Uint8}, data::Union(ASCIIString, UTF8String))
    ptr = convert(Ptr{Uint8}, c_realloc(ptr, sizeof(data)))
    unsafe_copy!(ptr, convert(Ptr{Uint8}, data), sizeof(data))
end

function pgdata(::Type{PostgresType{:varchar}}, ptr::Ptr{Uint8}, data::String)
    str = bytestring(data)
    ptr = convert(Ptr{Uint8}, c_realloc(ptr, sizeof(str)))
    unsafe_copy!(ptr, convert(Ptr{Uint8}, str), sizeof(str))
end

# @pgtypeproxy Uint8 Int16
# @pgtypeproxy Uint16 Int32
# @pgtypeproxy Uint32 Int64

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
        oids = [OID{int(PQftype(result, col))} for col in 0:(PQnfields(result)-1)]
        types = DataType[convert(PostgresType, x) for x in oids]
    else
        types = DataType[]
    end
    return PostgresResultHandle(result, types, PQntuples(result), PQnfields(result))
end

type PostgresStatementHandle <: DBI.StatementHandle
    db::PostgresDatabaseHandle
    stmtname::String
    paramtypes::Vector{DataType}
    executed::Int
    finished::Bool
    result::PostgresResultHandle

    function PostgresStatementHandle(db::PostgresDatabaseHandle, stmtname::String,
        paramtypes=DataType[], executed=0)
        new(db, stmtname, paramtypes, executed, false)
    end
end

function Base.copy(rh::PostgresResultHandle)
    PostgresResultHandle(PQcopyResult(result, PG_COPYRES_ATTRS | PG_COPYRES_TUPLES |
        PG_COPYRES_NOTICEHOOKS | PG_COPYRES_EVENTS), copy(rh.types), rh.ntuples, rh.nfields)
end

