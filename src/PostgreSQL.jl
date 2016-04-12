module PostgreSQL
    export  Postgres,
            executemany,
            copy_from,
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
end
