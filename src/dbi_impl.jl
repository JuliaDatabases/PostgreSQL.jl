function Base.connect(::Type{Postgres},
                      host::String="",
                      user::String="",
                      passwd::String="",
                      db::String="",
                      port::String="")
    conn = PQsetdbLogin(host, port, C_NULL, C_NULL, db, user, passwd)
    status = PQstatus(conn)

    if status != CONNECTION_OK
        errmsg = bytestring(PQerrorMessage(conn))
        PQfinish(conn)
        error(errmsg)
    end

    conn = PostgresDatabaseHandle(conn, status)
    finalizer(conn, DBI.disconnect)
    return conn
end

function Base.connect(::Type{Postgres},
                      host::String,
                      user::String,
                      passwd::String,
                      db::String,
                      port::Integer)
    Base.connect(Postgres, host, user, passwd, db, string(port))
end

# Note that for some reason, `do conn` notation
# doesn't work using this version of the function
function Base.connect(::Type{Postgres};
                      dsn::String="")
    conn = PQconnectdb(dsn)
    status = PQstatus(conn)
    if status != CONNECTION_OK
        errmsg = bytestring(PQerrorMessage(conn))
        PQfinish(conn)
        error(errmsg)
    end
    conn = PostgresDatabaseHandle(conn, status)
    finalizer(conn, DBI.disconnect)
    return conn
end

function DBI.disconnect(db::PostgresDatabaseHandle)
    if db.closed
        return
    else
        PQfinish(db.ptr)
        db.closed = true
        return
    end
end

function DBI.errcode(db::PostgresDatabaseHandle)
    return db.status = PQstatus(db.ptr)
end

function DBI.errstring(db::PostgresDatabaseHandle)
    return bytestring(PQerrorMessage(db.ptr))
end

function DBI.errcode(res::PostgresResultHandle)
    return PQresultStatus(res.ptr)
end

function DBI.errstring(res::PostgresResultHandle)
    return bytestring(PQresultErrorMessage(res.ptr))
end

DBI.errcode(stmt::PostgresStatementHandle) = DBI.errcode(stmt.result)
DBI.errstring(stmt::PostgresStatementHandle) = DBI.errstring(stmt.result)

function checkerrclear(result::Ptr{PGresult})
    status = PQresultStatus(result)

    try
        if status == PGRES_FATAL_ERROR
            statustext = bytestring(PQresStatus(status))
            errmsg = bytestring(PQresultErrorMessage(result))
            error("$statustext: $errmsg")
        end
    finally
        PQclear(result)
    end
end

escapeliteral(db::PostgresDatabaseHandle, value) = value
escapeliteral(db::PostgresDatabaseHandle, value::String) = escapeliteral(db, bytestring(value))

function escapeliteral(db::PostgresDatabaseHandle, value::Union(ASCIIString, UTF8String))
    strptr = PQescapeLiteral(db.ptr, value, sizeof(value))
    str = bytestring(strptr)
    PQfreemem(strptr)
    return str
end

Base.run(db::PostgresDatabaseHandle, sql::String) = checkerrclear(PQexec(db.ptr, sql))

hashsql(sql::String) = bytestring(string("__", hash(sql), "__"))

function getparamtypes(result::Ptr{PGresult})
    nparams = PQnparams(result)
    return [pgtype(OID{int(PQparamtype(result, i-1))}) for i = 1:nparams]
end

LIBC = @windows ? "msvcrt.dll" : :libc
strlen(ptr::Ptr{Uint8}) = ccall((:strlen, LIBC), Csize_t, (Ptr{Uint8},), ptr)

function getparams!(ptrs::Vector{Ptr{Uint8}}, params, types, sizes, lengths::Vector{Int32}, nulls)
    fill!(nulls, false)
    for i = 1:length(ptrs)
        if params[i] === nothing || params[i] === NA || params[i] === None
            nulls[i] = true
        else
            ptrs[i] = pgdata(types[i], ptrs[i], params[i])
            if sizes[i] < 0
                warn("Calling strlen--this should be factored out.")
                lengths[i] = strlen(ptrs[i]) + 1
            end
        end
    end
    return
end

function cleanupparams(ptrs::Vector{Ptr{Uint8}})
    for ptr in ptrs
        c_free(ptr)
    end
end

function DBI.prepare(db::PostgresDatabaseHandle, sql::String,
    types::Vector{DataType}=DataType[])
    stmtname = hashsql(sql)

    oids = Uint32[oid(t) for t in types]
    if isempty(oids)
        result = PQprepare(db.ptr, stmtname, sql, 0, C_NULL)
    else
        result = PQprepare(db.ptr, stmtname, sql, length(oids), pointer(oids))
    end

    checkerrclear(result)

    result = PQdescribePrepared(db.ptr, stmtname)
    types = getparamtypes(result)
    checkerrclear(result)

    stmt = PostgresStatementHandle(db, stmtname, types)
    finalizer(stmt, DBI.finish)
    return stmt
end

function DBI.finish(stmt::PostgresStatementHandle)
    if stmt.db.closed || stmt.finished
        return
    else
        Base.run(stmt.db, bytestring("DEALLOCATE \"$(stmt.stmtname)\";"))
        stmt.finished = true
        return
    end
end

function DBI.execute(stmt::PostgresStatementHandle)
    result = PQexecPrepared(stmt.db.ptr, stmt.stmtname, 0, C_NULL, C_NULL, C_NULL, PGF_TEXT)
    return stmt.result = PostgresResultHandle(result)
end

function DBI.execute(stmt::PostgresStatementHandle, params::Vector)
    nparams = length(params)

    if nparams != length(stmt.paramtypes)
        error("Number of parameters in statement ($nparams) does not match number of " *
            "parameter values ($(length(stmt.paramtypes))).")
    end

    sizes = zeros(Int64, nparams)
    lengths = zeros(Cint, nparams)
    param_ptrs = fill(convert(Ptr{Uint8}, 0), nparams)
    nulls = falses(nparams)
    for i = 1:nparams
        sizes[i] = sizeof(stmt.paramtypes[i])

        if sizes[i] > 0
            lengths[i] = sizes[i]
        end
    end
    formats = fill(PGF_TEXT, nparams)

    getparams!(param_ptrs, params, stmt.paramtypes, sizes, lengths, nulls)

    result = PQexecPrepared(stmt.db.ptr, stmt.stmtname, nparams,
        [convert(Ptr{Uint8}, nulls[i] ? C_NULL : param_ptrs[i]) for i = 1:nparams],
        pointer(lengths), pointer(formats), PGF_TEXT)

    cleanupparams(param_ptrs)

    return stmt.result = PostgresResultHandle(result)
end

function executemany{T<:AbstractVector}(stmt::PostgresStatementHandle,
        params::Union(DataFrame,AbstractVector{T}))
    nparams = isa(params, DataFrame) ? ncol(params) : length(params[1])
    nstmtparams = length(stmt.paramtypes)
    sizes = zeros(Int64, nparams)
    lengths = zeros(Cint, nparams)
    param_ptrs = fill(convert(Ptr{Uint8}, 0), nparams)
    nulls = falses(nparams)
    for i = 1:nparams
        sizes[i] = sizeof(stmt.paramtypes[i])

        if sizes[i] > 0
            lengths[i] = sizes[i]
        end
    end
    formats = fill(PGF_TEXT, nparams)

    result = C_NULL
    rowiter = isa(params, DataFrame) ? eachrow(params) : params
    for paramvec in rowiter
        getparams!(param_ptrs, paramvec, stmt.paramtypes, sizes, lengths, nulls)
        result = PQexecPrepared(stmt.db.ptr, stmt.stmtname, nparams,
            [convert(Ptr{Uint8}, nulls[i] ? C_NULL : param_ptrs[i]) for i = 1:nparams],
            pointer(lengths), pointer(formats), PGF_TEXT)
    end

    cleanupparams(param_ptrs)

    return stmt.result = PostgresResultHandle(result)
end

function DBI.fetchrow(stmt::PostgresStatementHandle)
    error("DBI API not fully implemented")
end

# Assumes the row exists and has the structure described in PostgresResultHandle
function unsafe_fetchrow(result::PostgresResultHandle, rownum::Integer)
    return Any[PQgetisnull(result.ptr, rownum, i-1) == 1 ? None :
               jldata(datatype, PQgetvalue(result.ptr, rownum, i-1))
               for (i, datatype) in enumerate(result.types)]
end

function unsafe_fetchcol_dataarray(result::PostgresResultHandle, colnum::Integer)
    return @data([PQgetisnull(result.ptr, i, colnum) == 1 ? NA :
            jldata(result.types[colnum+1], PQgetvalue(result.ptr, i, colnum))
            for i = 0:(PQntuples(result.ptr)-1)])
end

function DBI.fetchall(result::PostgresResultHandle)
    return Vector{Any}[row for row in result]
end

function DBI.fetchdf(result::PostgresResultHandle)
    df = DataFrame()
    for i = 0:(length(result.types)-1)
        df[symbol(bytestring(PQfname(result.ptr, i)))] = unsafe_fetchcol_dataarray(result, i)
    end

    return df
end

function Base.length(result::PostgresResultHandle)
    return PQntuples(result.ptr)
end

function Base.start(result::PostgresResultHandle)
    return 0
end

function Base.next(result::PostgresResultHandle, state)
    return (unsafe_fetchrow(result, state), state + 1)
end

function Base.done(result::PostgresResultHandle, state)
    return state >= result.nrows
end

# delegate statement iteration to result
Base.start(stmt::PostgresStatementHandle) = Base.start(stmt.result)
Base.next(stmt::PostgresStatementHandle, state) = Base.next(stmt.result, state)
Base.done(stmt::PostgresStatementHandle, state) = Base.done(stmt.result, state)
