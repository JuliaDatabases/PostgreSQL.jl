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

    return PostgresDatabaseHandle(conn, status)
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
    PQfinish(db.ptr)
    db.closed = true
    return
end

function DBI.errcode(db::PostgresDatabaseHandle)
    error("DBI API not fully implemented")
end

function DBI.errstring(db::PostgresDatabaseHandle)
    return bytestring(PQerrorMessage(db.ptr))
end

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

function DBI.prepare(db::PostgresDatabaseHandle, sql::String)
    stmtname = bytestring(string("__", hash(sql), "__"))

    result = PQprepare(db.ptr, stmtname, sql, 0, C_NULL)
    PQclear(result)

    return PostgresStatementHandle(db, stmtname)
end

function DBI.finish(stmt::PostgresStatementHandle)
    if stmt.db.closed
        print(STDERR, "WARNING: Connection is closed; no operation performed.")
    else
        Base.run(stmt.db, bytestring("DEALLOCATE \"$(stmt.stmtname)\";"))
    end
end

function DBI.execute(stmt::PostgresStatementHandle)
    result = PQexecPrepared(stmt.db.ptr, stmt.stmtname, 0, C_NULL, C_NULL, C_NULL, PGF_BINARY)
    return stmt.result = PostgresResultHandle(result)
end

function DBI.fetchrow(stmt::PostgresStatementHandle)
    error("DBI API not fully implemented")
end

# Assumes the row exists and has the structure described in PostgresResultHandle
function unsafe_fetchrow(result::PostgresResultHandle, rownum::Integer)
    return Any[PQgetisnull(result.ptr, rownum, i-1) == 1 ? None :
               jldata(PQgetvalue(result.ptr, rownum, i-1), datatype,
                      PQgetlength(result.ptr, rownum, i-1))
               for (i, datatype) in enumerate(result.types)]
end

function unsafe_fetchcol_dataarray(result::PostgresResultHandle, colnum::Integer)
    return @data([PQgetisnull(result.ptr, i, colnum) == 1 ? NA :
            jldata(PQgetvalue(result.ptr, i, colnum), result.types[colnum+1],
                   PQgetlength(result.ptr, i, colnum))
            for i = 0:(PQntuples(result.ptr)-1)])
end

function DBI.fetchall(result::PostgresResultHandle)
    return Vector{Any}[row for row in result]
end

function DBI.fetchdf(result::PostgresResultHandle)
    df = DataFrame()
    for i = 0:(length(result.types)-1)
        df[bytestring(PQfname(result.ptr, i))] = unsafe_fetchcol_dataarray(result, i)
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
