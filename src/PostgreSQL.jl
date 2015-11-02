module PostgreSQL
    export  Postgres,
            executemany,
            escapeliteral

    using BinDeps
    @BinDeps.load_dependencies

    include("libpq_interface.jl")
    using .libpq_interface
    using DBI
    using DataFrames
    using DataArrays

    include("types.jl")
    include("dbi_impl.jl")

    include("dbapi_impl.jl")
end
