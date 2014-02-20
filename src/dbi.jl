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
DBI.errcode(stmt::PostgresStatementHandle) = DBI.errcode(stmt.result)

function Base.run(db::PostgresDatabaseHandle, sql::String)
    result = PQexec(db.ptr, sql)
    status = PQresultStatus(result)

    try
        if status == PGRES_FATAL_ERROR  # or...
            statustext = bytestring(PQresStatus(status))
            errmsg = bytestring(PQresultErrorMessage(result))
            error("$statustext: $errmsg")
        end
    finally
        PQclear(result)
    end

    return
end

hashsql(sql::String) = bytestring(string("__", hash(sql), "__"))

function getparamtypes(result::Ptr{PGresult})
    nparams = PQnparams(result)
    return [pgtype(OID{int(PQparamtype(result, i-1))}) for i = 1:nparams]
end

function getparams!(ptrs::Vector{Ptr{Uint8}}, params, types, lengths)
    for i = 1:length(ptrs)
        ptrs[i] = pgdata(types[i], ptrs[i], params[i])
        if lengths[i] < 0
            lengths[i] = ccall((:strlen, :libc), Csize_t, (Ptr{Uint8},), p)
        end
    end
end

function cleanupparams(ptrs::Vector{Ptr{Uint8}})
    for ptr in ptrs
        if ptr != C_NULL
            c_free(ptr)
        end
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
    PQclear(result)

    result = PQdescribePrepared(db.ptr, stmtname)
    types = getparamtypes(result)
    PQclear(result)

    stmt = PostgresStatementHandle(db, stmtname, types)
    finalizer(stmt, DBI.finish)
    return stmt
end

function DBI.finish(stmt::PostgresStatementHandle)
    if stmt.db.closed || stmt.finished
        return
    else
        Base.run(stmt.db, bytestring("DEALLOCATE \"$(stmt.stmtname)\";"))
        return
    end
end

function DBI.execute(stmt::PostgresStatementHandle)
    result = PQexecPrepared(stmt.db.ptr, stmt.stmtname, 0, C_NULL, C_NULL, C_NULL, PGF_BINARY)
    return stmt.result = PostgresResultHandle(result)
end

function DBI.execute(stmt::PostgresStatementHandle, params::Vector)
    nparams = length(params)

    if nparams != length(stmt.paramtypes)
        error("Number of parameters in statement ($nparams) does not match number of " *
            "parameter values ($(length(stmt.paramtypes))).")
    end

    lengths = zeros(Uint32, nparams)
    param_ptrs = fill(pointer(Uint8, uint64(0)), nparams)
    for i = 1:nparams
        lengths[i] = sizeof(stmt.paramtypes[i])

        if lengths[i] > 0
            param_ptrs[i] = c_malloc(lengths[i])
        end
    end
    formats = fill(PGF_BINARY, nparams)

    getparams!(param_ptrs, params, stmt.paramtypes, lengths)
    result = PQexecPrepared(stmt.db.ptr, stmt.stmtname, nparams,
        param_ptrs, lengths, formats, PGF_BINARY)

    cleanupparams(param_ptrs)

    return stmt.result = PostgresResultHandle(result)
end

function executemany(stmt::PostgresStatementHandle, params::Vector{Vector})
    nparams = length(params[1])
    nstmtparams = length(stmt.paramtypes)
    lengths = zeros(Uint32, nparams)
    param_ptrs = fill(pointer(Uint8, uint64(0)), nparams)
    for i = 1:nparams
        lengths[i] = sizeof(stmt.paramtypes[i])

        if lengths[i] > 0
            param_ptrs[i] = c_malloc(lengths[i])
        end
    end
    formats = fill(PGF_BINARY, nparams)

    for paramvec in params
        getparams!(param_ptrs, paramvec, stmt.paramtypes, lengths)
        result = PQexecPrepared(stmt.db.ptr, stmt.stmtname, nparams,
            param_ptrs, lengths, formats, PGF_BINARY)
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
               jldata(datatype, PQgetvalue(result.ptr, rownum, i-1),
                      PQgetlength(result.ptr, rownum, i-1))
               for (i, datatype) in enumerate(result.types)]
end

function unsafe_fetchcol_dataarray(result::PostgresResultHandle, colnum::Integer)
    return @data([PQgetisnull(result.ptr, i, colnum) == 1 ? NA :
            jldata(result.types[colnum+1], PQgetvalue(result.ptr, i, colnum),
            PQgetlength(result.ptr, i, colnum))
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
