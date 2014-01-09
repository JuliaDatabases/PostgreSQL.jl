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
        PGclear(result)
    end

    return
end
