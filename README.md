# PostgreSQL.jl

[![Build Status](https://travis-ci.org/JuliaDB/PostgreSQL.jl.svg)](https://travis-ci.org/JuliaDB/PostgreSQL.jl)  [![Coverage Status](https://img.shields.io/coveralls/JuliaDB/PostgreSQL.jl.svg)](https://coveralls.io/r/JuliaDB/PostgreSQL.jl)  [![codecov.io](http://codecov.io/github/JuliaDB/PostgreSQL.jl/coverage.svg)](http://codecov.io/github/JuliaDB/PostgreSQL.jl)

An interface to PostgreSQL from Julia. Uses libpq (the C PostgreSQL API) and obeys the [DBI.jl protocol](https://github.com/JuliaDB/DBI.jl).


## Maintenance Notice

I can no longer spend work time on this so this project is in maintenance mode (accepting PRs and attempting to resolve issues). New code on the `dbapi` branch (https://github.com/JuliaDB/DBAPI.jl) represents the most recent work, which I will continue if I am in a position to do so again.


## Usage

```julia
using DBI
using PostgreSQL

conn = connect(Postgres, "localhost", "username", "password", "dbname", 5432)

stmt = prepare(conn, "SELECT 1::bigint, 2.0::double precision, 'foo'::character varying, " *
					 "'foo'::character(10);")
result = execute(stmt)
for row in result
	# code
end

finish(stmt)

disconnect(conn)
```

### Block Syntax

```julia
using DBI
using PostgreSQL

connect(Postgres, "localhost", "username", "password", "dbname", 5432) do conn
	#code
end
```


## Requirements

* [DBI.jl](https://github.com/JuliaDB/DBI.jl)
* [DataFrames.jl](https://github.com/JuliaStats/DataFrames.jl) >= v0.8.0
* [DataArrays.jl](https://github.com/JuliaStats/DataArrays.jl) >= v0.3.4 for Julia 0.4, v0.3.8 for Julia 0.5
* libpq shared library (comes with a standard PostgreSQL client installation)
* Julia 0.4

Tests require a local PostgreSQL server with a postgres user/database (installed by default with PostgreSQL server installations) with trusted authentication from localhost.


## Systems

* Tested on Funtoo Linux and Windows 8
* Should work on other systems provided libpq is avaiable (please file an issue if this is not the case)


## TODO (soon)

* Implement more default PostgreSQL type handling
* Test type handling overrides
* More comprehensive error handling and tests
* Support for COPY


## TODO (not soon)

* Asynchronous connection support
* Asynchronous Julia for handling asynchronous connections
* Testing and compatibility with multiple versions of PostgreSQL and libpq
