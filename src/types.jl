abstract PostgresDataType

abstract AbstractOID
type OID{N} <: AbstractOID end

macro pgtype(pgtypename, oid)
    quote
        type $pgtypename <: PostgresDataType
            data::Array{Uint8}
        end
        $(esc(:oid))(::Type{$pgtypename}) = OID{$oid}
        $(esc(:pgtype))(::Type{OID{$oid}}) = $pgtypename
#        pgformat(::Type{Oid{$oid}}) = :PG_BINARY
        function $(esc(:jldata)){T<:AbstractOID}(ptr::Ptr{Uint8}, oid::Type{T}, length)
            jldata(ptr, pgtype(oid), length)
        end
    end
end


@pgtype PostgresBool 16
@pgtype PostgresByteArray 17
@pgtype PostgresInt64 20
@pgtype PostgresInt32 23
@pgtype PostgresInt16 21
@pgtype PostgresFloat64 701
@pgtype PostgresFloat32 700
@pgtype PostgresBlankPaddedChar 1042
@pgtype PostgresVarChar 1043

function jldata(ptr::Ptr{Uint8}, ::Type{PostgresBool}, length)
    pointer_to_array(convert(Ptr{Bool}, ptr), 0)[1]
end

# TODO: Add type hierarchy for numbers
function jldata(ptr::Ptr{Uint8}, ::Type{PostgresInt64}, length)
    ntoh(pointer_to_array(convert(Ptr{Int64}, ptr), (1,))[1])
end

function jldata(ptr::Ptr{Uint8}, ::Type{PostgresInt32}, length)
    ntoh(pointer_to_array(convert(Ptr{Int32}, ptr), (1,))[1])
end

function jldata(ptr::Ptr{Uint8}, ::Type{PostgresInt16}, length)
    ntoh(pointer_to_array(convert(Ptr{Int16}, ptr), (1,))[1])
end

function jldata(ptr::Ptr{Uint8}, ::Type{PostgresFloat64}, length)
    ntoh(pointer_to_array(convert(Ptr{Float64}, ptr), (1,))[1])
end

function jldata(ptr::Ptr{Uint8}, ::Type{PostgresFloat32}, length)
    ntoh(pointer_to_array(convert(Ptr{Float32}, ptr), (1,))[1])
end

function jldata(ptr::Ptr{Uint8}, ::Type{PostgresBlankPaddedChar}, length)
    bytestring(ptr)
end

function jldata(ptr::Ptr{Uint8}, ::Type{PostgresVarChar}, length)
    bytestring(ptr)
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
        oids = [OID{int(PQftype(result, col))} for col in 0:(PQnfields(result)-1)]
        types = DataType[pgtype(x) for x in oids]
    else
        types = DataType[]
    end
    return PostgresResultHandle(result, types, PQntuples(result), PQnfields(result))
end

type PostgresStatementHandle <: DBI.StatementHandle
    db::PostgresDatabaseHandle
    stmtname::String
    executed::Int
    paramtypes::Vector{Oid}
    result::PostgresResultHandle

    function PostgresStatementHandle(db::PostgresDatabaseHandle, stmtname::String)
        new(db, stmtname, 0, Oid[])
    end
end

function Base.copy(rh::PostgresResultHandle)
    PostgresResultHandle(PQcopyResult(result, PG_COPYRES_ATTRS | PG_COPYRES_TUPLES |
        PG_COPYRES_NOTICEHOOKS | PG_COPYRES_EVENTS), copy(rh.types), rh.ntuples, rh.nfields)
end

