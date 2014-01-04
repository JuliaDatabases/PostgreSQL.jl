abstract Postgres <: DBI.DatabaseSystem

type PostgresDatabaseHandle <: DBI.DatabaseHandle
    ptr::Ptr{PGconn}
    status::ConnStatusType
    closed::Bool

    function PostgresDatabaseHandle(ptr::Ptr{PGconn}, status::ConnStatusType)
        new(ptr, status, false)
    end
end

type PostgresStatementHandle <: DBI.StatementHandle
    db::PostgresDatabaseHandle
    stmt_name::Ptr{Uint8}
    executed::Int

    function PostgresStatementHandle(db::PostgresDatabaseHandle, stmt::Ptr{Uint8})
        new(db, ptr, 0)
    end
end

