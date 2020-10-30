module PostgreSQL

import LibPQ, DBInterface

struct Connection <: DBInterface.Connection
    inner::LibPQ.Connection
end

struct Stmt <: DBInterface.Statement
    inner::LibPQ.Statement
end

DBInterface.connect(::Type{Connection}, args...; kw...) = Connection(LibPQ.Connection(args...; kw...))

DBInterface.close!(conn::Connection) = LibPQ.close(conn.inner)

function DBInterface.prepare(conn::Connection, sql::AbstractString)
    # The definition of the sql is different for `DBInterface` and `libPQ`.
    
    sql_new = sql
    i = 1
    while true
        r = match(r"(:[\w]+)|([\?])", sql_new)
        if isnothing(r)
            break
        end
        sql_new = sql_new[1:r.offset - 1] * "\$$i" * sql_new[r.offset + length(r.match):end]
        i += 1
    end

    return Stmt(LibPQ.prepare(conn.inner, sql_new))
end

DBInterface.execute(stmt::Stmt, params=()) = LibPQ.execute(stmt.inner, params)

        
end