import Compat: Libc, @static, is_windows

function Base.connect(::Type{Postgres},
                      host::AbstractString,
                      user::AbstractString,
                      passwd::AbstractString,
                      db::AbstractString,
                      port::AbstractString="")
    conn = PQsetdbLogin(host, port, C_NULL, C_NULL, db, user, passwd)
    status = PQstatus(conn)

    if status != CONNECTION_OK
        errmsg = unsafe_string(PQerrorMessage(conn))
        PQfinish(conn)
        error(errmsg)
    end

    conn = PostgresDatabaseHandle(conn, status)
    finalizer(conn, DBI.disconnect)
    return conn
end

function Base.connect(::Type{Postgres},
                      host::AbstractString,
                      user::AbstractString,
                      passwd::AbstractString,
                      db::AbstractString,
                      port::Integer)
    Base.connect(Postgres, host, user, passwd, db, string(port))
end

# Note that for some reason, `do conn` notation
# doesn't work using this version of the function
function Base.connect(::Type{Postgres};
                      dsn::AbstractString="")
    conn = PQconnectdb(dsn)
    status = PQstatus(conn)
    if status != CONNECTION_OK
        errmsg = unsafe_string(PQerrorMessage(conn))
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
    return unsafe_string(PQerrorMessage(db.ptr))
end

function DBI.errcode(res::PostgresResultHandle)
    return PQresultStatus(res.ptr)
end

function DBI.errstring(res::PostgresResultHandle)
    return unsafe_string(PQresultErrorMessage(res.ptr))
end

DBI.errcode(stmt::PostgresStatementHandle) = DBI.errcode(stmt.result)
DBI.errstring(stmt::PostgresStatementHandle) = DBI.errstring(stmt.result)

function checkerrclear(result::Ptr{PGresult})
    status = PQresultStatus(result)

    try
        if status == PGRES_FATAL_ERROR
            statustext = unsafe_string(PQresStatus(status))
            errmsg = unsafe_string(PQresultErrorMessage(result))
            error("$statustext: $errmsg")
        end
    finally
        PQclear(result)
    end
end

escapeliteral(db::PostgresDatabaseHandle, value) = value

function escapeliteral(db::PostgresDatabaseHandle, value::AbstractString)
    strptr = PQescapeLiteral(db.ptr, value, sizeof(value))
    str = unsafe_string(strptr)
    PQfreemem(strptr)
    return str
end

function escapeidentifier(db::PostgresDatabaseHandle, value::AbstractString)
    strptr = PQescapeIdentifier(db.ptr, value, sizeof(value))
    str = unsafe_string(strptr)
    PQfreemem(strptr)
    return str
end

Base.run(db::PostgresDatabaseHandle, sql::AbstractString) = checkerrclear(PQexec(db.ptr, sql))

function checkcopyreturnval(db::PostgresDatabaseHandle, returnval::Int32)
    if returnval == -1
        errcode = unsafe_string(DBI.errcode(db))
        errmsg = unsafe_string(DBI.errmsg(db))
        error("Error $errcode: $errmsg")
    end
end

function copy_from(db::PostgresDatabaseHandle, table::AbstractString,
                   filename::AbstractString, format::AbstractString)
    f = open(filename)
    try
        Base.run(db, string("COPY ", escapeidentifier(db, table), " FROM STDIN ", format))
        for row in eachline(f)
            # send row to postgres
            checkcopyreturnval(db, PQputCopyData(db.ptr, row, length(row)))
        end
        checkcopyreturnval(db, PQputCopyEnd(db.ptr, C_NULL))
    finally
        close(f)
    end
    return checkerrclear(PQgetResult(db.ptr))
end

hashsql(sql::AbstractString) = String(string("__", hash(sql), "__"))

function getparamtypes(result::Ptr{PGresult})
    nparams = PQnparams(result)
    return [pgtype(OID{Int(PQparamtype(result, i-1))}) for i = 1:nparams]
end

LIBC = @static is_windows() ? "msvcrt.dll" : :libc
strlen(ptr::Ptr{UInt8}) = ccall((:strlen, LIBC), Csize_t, (Ptr{UInt8},), ptr)

function getparams!(ptrs::Vector{Ptr{UInt8}}, params, types, sizes, lengths::Vector{Int32}, nulls)
    fill!(nulls, false)
    for i = 1:length(ptrs)
        if params[i] === nothing || params[i] === NA || params[i] === Union{}
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

function cleanupparams(ptrs::Vector{Ptr{UInt8}})
    for ptr in ptrs
        Libc.free(ptr)
    end
end

DBI.prepare(db::PostgresDatabaseHandle, sql::AbstractString) = PostgresStatementHandle(db, sql)

DBI.finish(stmt::PostgresStatementHandle) = nothing

function DBI.execute(stmt::PostgresStatementHandle)
    result = PQexec(stmt.db.ptr, stmt.stmt)
    return stmt.result = PostgresResultHandle(result)
end

function DBI.execute(stmt::PostgresStatementHandle, params::Vector)
    nparams = length(params)

    if nparams > 0 && isempty(stmt.paramtypes)
        paramtypes = [pgtype(typeof(p)) for p in params]
    else
        paramtypes = stmt.paramtypes
    end

    if nparams != length(paramtypes)
        error("Number of parameters in statement ($(length(stmt.paramtypes))) does not match number of " *
            "parameter values ($nparams).")
    end

    sizes = zeros(Int64, nparams)
    lengths = zeros(Cint, nparams)
    param_ptrs = fill(convert(Ptr{UInt8}, 0), nparams)
    nulls = falses(nparams)
    for i = 1:nparams
        if paramtypes[i] === nothing
            paramtypes[i] = pgtype(typeof(params[i]))
        end

        sizes[i] = sizeof(paramtypes[i])

        if sizes[i] > 0
            lengths[i] = sizes[i]
        end
    end
    formats = fill(PGF_TEXT, nparams)

    getparams!(param_ptrs, params, paramtypes, sizes, lengths, nulls)

    oids = Oid[convert(Oid, oid(p)) for p in paramtypes]

    result = PQexecParams(stmt.db.ptr, stmt.stmt, nparams,
        oids,
        [convert(Ptr{UInt8}, nulls[i] ? C_NULL : param_ptrs[i]) for i = 1:nparams],
        pointer(lengths), pointer(formats), PGF_TEXT)

    cleanupparams(param_ptrs)

    return stmt.result = PostgresResultHandle(result)
end

function executemany{T<:AbstractVector}(stmt::PostgresStatementHandle,
        params::Union{DataFrame,AbstractVector{T}})
    nparams = isa(params, DataFrame) ? ncol(params) : length(params[1])

    if nparams > 0 && isempty(stmt.paramtypes)
        if isa(params, DataFrame)
            paramtypes = collect(PostgresType, eltypes(params))
        else
            paramtypes = [pgtype(typeof(p)) for p in params[1]]
        end
    else
        paramtypes = stmt.paramtypes
    end

    if nparams != length(paramtypes)
        error("Number of parameters in statement ($(length(stmt.paramtypes))) does not match number of " *
            "parameter values ($nparams).")
    end

    sizes = zeros(Int64, nparams)
    lengths = zeros(Cint, nparams)
    param_ptrs = fill(convert(Ptr{UInt8}, 0), nparams)
    nulls = falses(nparams)
    for i = 1:nparams
        if paramtypes[i] === nothing
            paramtypes[i] = pgtype(typeof(params[1][i]))
        end

        if sizes[i] > 0
            lengths[i] = sizes[i]
        end
    end
    formats = fill(PGF_TEXT, nparams)

    result = C_NULL
    rowiter = isa(params, DataFrame) ? eachrow(params) : params
    for paramvec in rowiter
        getparams!(param_ptrs, paramvec, paramtypes, sizes, lengths, nulls)

        oids = Oid[convert(Oid, oid(p)) for p in paramtypes]

        result = PQexecParams(stmt.db.ptr, stmt.stmt, nparams,
            oids,
            [convert(Ptr{UInt8}, nulls[i] ? C_NULL : param_ptrs[i]) for i = 1:nparams],
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
    return Any[PQgetisnull(result.ptr, rownum, i-1) == 1 ? Union{} :
               jldata(datatype, PQgetvalue(result.ptr, rownum, i-1))
               for (i, datatype) in enumerate(result.types)]
end

function unsafe_fetchcol_dataarray(result::PostgresResultHandle, colnum::Integer)
    return Any[PQgetisnull(result.ptr, i, colnum) == 1 ? NA :
            jldata(result.types[colnum+1], PQgetvalue(result.ptr, i, colnum))
            for i = 0:(PQntuples(result.ptr)-1)]
end

function DBI.fetchall(result::PostgresResultHandle)
    return Vector{Any}[row for row in result]
end

function DBI.fetchdf(result::PostgresResultHandle)
    df = DataFrame()
    for i = 0:(length(result.types)-1)
        df[Symbol(unsafe_string(PQfname(result.ptr, i)))] = unsafe_fetchcol_dataarray(result, i)
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
