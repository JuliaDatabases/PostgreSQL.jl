module PostgreSQL
    export  Postgres,
            executemany,
            escapeliteral

    include("libpq.jl")
    using .libpq
    using DBI
    using DataFrames
    using DataArrays

    include("types.jl")
    include("dbi_impl.jl")
end
