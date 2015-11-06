module Connections

import DataStructures: OrderedDict
using ReadWriteLocks

using ..PostgreSQLDBAPIBase
import ..PostgreSQLDBAPIBase: pq,
    ConnectionParameters,
    DSNConnectionParameters,
    SimpleConnectionParameters,
    checkmem,
    PostgreSQLConnectionError
import ..DSN: generate_dsn, is_valid_dsn


# ConnectionParameters
function ConnectionParameters(dsn::ByteString; kwargs...)
    if !is_valid_dsn(dsn)
        throw(PostgreSQLConnectionError("Invalid connection URI: $dsn"))
    end

    params = DSNConnectionParameters(ByteString[], ByteString[], dsn)

    params["dbname"] = dsn

    return ConnectionParameters(params; kwargs...)
end

function ConnectionParameters(; kwargs...)
    params = SimpleConnectionParameters(ByteString[], ByteString[])

    return ConnectionParameters(params; kwargs...)
end

function ConnectionParameters(params::ConnectionParameters; kwargs...)
    for (k, v) in kwargs
        params[bytestring(string(k))] = bytestring(v)
    end

    return params
end

expand_dbname(::DSNConnectionParameters) = true
expand_dbname(::SimpleConnectionParameters) = false

Base.length(params::ConnectionParameters) = length(params.keys)

function Base.setindex!(params::ConnectionParameters, value::ByteString, key::ByteString)
    push!(params.keys, key)
    push!(params.values, value)
end

function Base.getindex(params::ConnectionParameters, key::ByteString)
    ind = findlast(params.keys, key)

    if ind == 0
        throw(KeyError(key))
    else
        return params.values[ind]
    end
end


# PostgreSQLConnection
type PostgreSQLConnection <: DatabaseConnection{PostgreSQLInterface}
    ptr::Ptr{Void}
    params::ConnectionParameters
    finished::Bool
    lock::ReadWriteLock

    function PostgreSQLConnection(
        ptr::Ptr{Void},
        params::ConnectionParameters,
        finished::Bool,
    )
        conn = new(ptr, params, finished, ReadWriteLock())
        finalizer(conn, finish)
        return conn
    end
end

function finish(conn::PostgreSQLConnection)
    wlock = write_lock(conn.lock)
    lock!(wlock)
    (conn_ptr, conn.ptr) = (conn.ptr, C_NULL)
    if !conn.finished
        pq.PQfinish(conn_ptr)
    end
    unlock!(wlock)
end

function PostgreSQLConnection(ptr::Ptr{Void}, params::ConnectionParameters)
    return PostgreSQLConnection(ptr, params, false)
end

function Base.isopen(conn::PostgreSQLConnection)
    rlock = read_lock(conn.lock)
    lock!(rlock)
    conn_is_open = !finished && pq.PQstatus(conn.ptr) == pq.CONNECTION_OK
    unlock!(rlock)

    return conn_is_open
end

function Base.close(conn::PostgreSQLConnection)
    finish(conn)
    return nothing
end

function show(io::IO, connection::PostgreSQLConnection)
    print(io,
        typeof(connection),
        "(params=$(generate_dsn(connection)), closed=$(!isopen(connection)))",
    )
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
    # we don't have to worry about locking in here as only we have access to the new
    # connection
    conn = PostgreSQLConnection(
        pq.PQconnectStartParams(
            params.keys,
            params.values,
            expand_dbname(params) ? pq.EXPAND_DBNAME : pq.NO_EXPAND_DBNAME,
        ),
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
        "Failed to connect to $(generate_dsn(conn.params))",
        error_message(conn),
    ))
end

function error_message(conn::PostgreSQLConnection)
    rlock = read_lock(conn.lock)
    lock!(rlock)
    if !conn.finished
        message = bytestring(pq.PQerrorMessage(conn.ptr))
    else
        message = "Unknown error: PostgreSQL connection has been destroyed.\n"
    end
    unlock!(rlock)

    return message
end


end
