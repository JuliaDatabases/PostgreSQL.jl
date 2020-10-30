# PostgreSQL.jl
A wrapper for PostgreSQL databases using `libPQ.jl` supporting `DBInterface.jl` syntax.

## Supported
- `conn = DBInterface.connect(T, args...; kw...)`
- `stmt = DBInterface.prepare(conn, "INSERT INTO test_table VALUES(?, ?)")`
- `DBInterface.execute(stmt, [1, 3.14])`
- `stmt = DBInterface.prepare(conn, "INSERT INTO test_table VALUES(:col1, :col2)")`
- `DBInterface.execute(stmt, (col1=1, col2=3.14))`
- `DBInterface.executemany(stmt, (col1=[1,2,3,4,5], col2=[3.14, 1.23, 2.34 3.45, 4.56]))`
- `DBInterface.close!(conn)`

## Not Supported Yet
- `DBInterface.Cursor`
- `close!(stmt::Statement)`
- `close!(x::Cursor)`