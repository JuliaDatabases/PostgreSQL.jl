module Connections

using ..PostgreSQLDBAPIBase
import PostgreSQLDBAPIBase: pq

import DataStructures: OrderedDict

# this will catch at least a few errors in advance
const VALID_DSN = r"^postgres(ql)?://"

immutable ConnectionParameters
    keys::Vector{ByteString}
    values::Vector{ByteString}
    expand_dbname::Bool
end

function ConnectionParameters(dsn::ByteString; kwargs...)
    params = ConnectionParameters(ByteString[], ByteString[], true)

    if !ismatch(VALID_DSN, dsn)
        throw(PostgreSQLConnectionError("Invalid connection URI: $dsn"))
    end

    params["dbname"] = dsn

    return ConnectionParameters(params; kwargs...)
end

function ConnectionParameters(; kwargs...)
    params = ConnectionParameters(ByteString[], ByteString[], false)

    return ConnectionParameters(params; kwargs...)
end

function ConnectionParameters(params::ConnectionParameters; kwargs...)
    for (k, v) in kwargs
        params[bytestring(k)] = bytestring(v)
    end

    return params
end

function setindex!(params::ConnectionParameters, value::ByteString, key::ByteString)
    push!(params.keys, key)
    push!(params.values, value)
end

type PostgreSQLConnection <: DatabaseConnection{PostgreSQLInterface}
    ptr::Ptr{Void}
    params::ConnectionParameters
    finished::Bool
    lock::ReentrantLock

    function PostgreSQLConnection(
        ptr::Ptr{Void},
        params::ConnectionParameters,
        finished::Bool,
    )
        conn = new(ptr, params, finished, ReentrantLock())
        finalizer(conn, finish)
        return conn
    end
end

function finish(conn::PostgreSQLConnection)
    lock(conn.lock)
    (conn_ptr, conn.ptr) = (conn.ptr, C_NULL)
    if !conn.finished
        pq.PQfinish(conn_ptr)
    end
    unlock(conn.lock)
end

function PostgreSQLConnection(ptr::Ptr{Void}, params::ConnectionParameters)
    return PostgreSQLConnection(ptr, params, false)
end

function Base.isopen(conn::PostgreSQLConnection)
    return !finished && pq.PQstatus(conn.ptr) == pq.CONNECTION_OK
end

function Base.close(conn::PostgreSQLConnection)
    finish(conn)
    return nothing
end

immutable PostgreSQLConnectionError <: DatabaseError{PostgreSQLInterface}
    msg::ByteString
    reason::ByteString
end

function Base.showerror(io::IO, err::PostgreSQLConnectionError)
    print(io, err.reason, err.msg)
end

type PostgreSQLConnectionFuture
    connection::PostgreSQLConnection
    success::Channel{Bool}
end

function Base.connect(::Type{PostgreSQLInterface}, args...; kwargs...)
    return fetch(async_connect(args...; kwargs...))
end

function async_connect(args...; kwargs...)
    params = ConnectionParameters(args...; kwargs...)

    return async_connect(params)
end

function async_connect(params::ConnectionParameters)
    conn = PostgreSQLConnection(
        pq.PQconnectStart(params.keys, params.values, params.expand_dbname),
        params,
    )
    checkmem(conn.ptr)

    if pq.PQstatus(conn.ptr) == pq.CONNECTION_BAD
        connection_failed(conn)
    end

    # instructions for this loop lie at
    # http://www.postgresql.org/docs/9.4/static/libpq-connect.html#LIBPQ-PQCONNECTSTARTPARAMS
    channel = Channel{Bool}(1)
    @async begin
        socket = RawFD(pq.PQsocket(conn.ptr))
        status = pq.PGRES_POLLING_WRITING
        while true
            if status == pq.PGRES_POLLING_WRITING
                poll_fd(socket; readable=false, writable=true)
            elseif status == pq.PGRES_POLLING_READING
                poll_fd(socket; readable=true, writable=false)
            elseif status == pq.PGRES_POLLING_OK
                put!(channel, true)
                break
            else
                put!(channel, false)
                break
            end

            status = pq.PQconnectPoll(conn.ptr)
        end
    end

    return PostgreSQLConnectionFuture(conn, channel)
end

function Base.wait(future::PostgreSQLConnectionFuture)
    successful = fetch(future.success)

    if !successful || pq.PQstatus(future.connection.ptr) == pq.CONNECTION_BAD
        connection_failed(future.connection)
    end

    return nothing
end

function Base.fetch(future::PostgreSQLConnectionFuture)
    wait(future)

    return future.connection
end

"""
The connection has failed, so throw an error.
"""
function connection_failed(conn::PostgreSQLConnection)
    throw(PostgreSQLConnectionError(
        "Failed to connect to $(conn.dsn)",
        bytestring(pq.PQerrorMessage(conn.ptr)),
    ))
end

function generate_dsn(params::ConnectionParameters)
    dsn_index = params.expand_dbname ? findfirst(params.keys, "dbname") : 0

    if dsn_index > 0
        start_string = params.values[dsn_index]
    else
        start_string = "postgresql:///?"
    end


end

end
