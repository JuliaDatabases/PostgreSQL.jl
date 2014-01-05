function Base.connect(::Type{Postgres}, 
                      host::String="", 
                      user::String="", 
                      passwd::String="",
                      db::String="",
                      port::String="")
    conn = PQsetdbLogin(host, port, C_NULL, C_NULL, db, user, passwd)
    status = PQstatus(conn)

    if status != CONNECTION_OK
        errmsg = copy(bytestring(PQerrorMessage(conn)))
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
    return copy(bytestring(PQerrorMessage(db.ptr)))
end
