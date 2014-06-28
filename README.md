# PostgreSQL.jl

An interface to PostgreSQL from Julia. Uses libpq (the C PostgreSQL API) and obeys the [DBI.jl protocol](https://github.com/JuliaDB/DBI.jl).


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
* [DataFrames.jl](https://github.com/JuliaStats/DataFrames.jl) > v0.5.5 (HEAD, will work with previous versions for some cases)
* [DataArrays.jl](https://github.com/JuliaStats/DataArrays.jl) >= v0.1.2
* libpq shared library (comes with a standard PostgreSQL client installation)
* julia 0.3


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
