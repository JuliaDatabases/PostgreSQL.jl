module PostgreSQLDBAPIBase

using Reexport

export PostgreSQLInterface

@reexport using DBAPI

import ...libpq_interface

pq = libpq_interface

immutable PostgreSQLInterface <: DatabaseInterface end

if !isdefined(:Mutex)
    typealias Mutex ReentrantLock

    lock!(x::Mutex) = lock(x)
    unlock!(x::Mutex) = unlock(x)
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
