function testsameness(a, b)
    try
        @test is(a, b)
    catch
        println(a, "::", typeof(a), " is not ", b, "::", typeof(b))
        rethrow()
    end
end

function testdberror(dbobj, expected)
    try
        @test errcode(dbobj) == expected
    catch
        println(errstring(dbobj))
        println(bytestring(PostgreSQL.PQresStatus(expected)))
        rethrow()
    end
end
