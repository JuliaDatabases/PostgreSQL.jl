using DBI
using Compat
using PostgreSQL
if VERSION >= v"0.5"
  using Base.Test
else
  using BaseTestNext
  const Test = BaseTestNext
end

include("testutils.jl")
@testset "Main" begin
    include("connection.jl")
    # include("dbi_impl.jl")
    # include("data.jl")
    # include("postgres.jl")
    # include("dataframes_impl.jl")
end
