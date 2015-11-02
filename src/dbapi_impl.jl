"""
This module is intended to replace the base module of this package.
"""
module PostgreSQLDBAPI

@reexport using .PostgreSQLDBAPIBase
@reexport using .Connections

include("dbapi/base.jl")
include("dbapi/connection.jl")


end
