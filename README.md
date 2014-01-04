# PostgreSQL.jl

An interface to PostgreSQL from Julia. Uses libpq (the C PostgreSQL API) and obeys the [DBI.jl protocol](https://github.com/johnmyleswhite/DBI.jl).


## Usage

```julia
using DBI
using PostgreSQL

conn = connect(Postgres, "localhost", "username", "password", "dbname", 5432)
# code
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

* [DBI.jl](https://github.com/johnmyleswhite/DBI.jl)
* libpq shared library (comes with a standard PostgreSQL client installation)


## Systems

* Tested on Funtoo Linux
* Should work on other systems provided libpq is avaiable (please file an issue if this is not the case)
