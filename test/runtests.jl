using DBI
using PostgreSQL
using Base.Test

include("testutils.jl")

include("connection.jl")
include("dbi_impl.jl")
include("data.jl")
include("postgres.jl")
include("dataframes_impl.jl")
include("dbapi/connection.jl")
