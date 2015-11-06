module PostgreSQLDBAPIBase

using Reexport

export PostgreSQLInterface

@reexport using DBAPI

import ...libpq_interface

pq = libpq_interface

immutable PostgreSQLInterface <: DatabaseInterface end

abstract ConnectionParameters

immutable DSNConnectionParameters <: ConnectionParameters
    keys::Vector{ByteString}
    values::Vector{ByteString}
    dsn::ByteString
end

immutable SimpleConnectionParameters <: ConnectionParameters
    keys::Vector{ByteString}
    values::Vector{ByteString}
end


"""
libpq will return a null pointer when it can't allocate memory. Here we check
for that and throw an error if necessary.
"""
function checkmem(ptr)
    if ptr == C_NULL
        throw(OutOfMemoryError())
    end
end

end
