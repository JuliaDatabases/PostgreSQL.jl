module DSN

export is_valid_dsn, generate_dsn

import ..PostgreSQLDBAPIBase: ConnectionParameters

# this will catch at least a few errors in advance
const VALID_DSN = r"^postgres(ql)?://"

is_valid_dsn(dsn::ByteString) = match(VALID_DSN, dsn)

"""
Generates a dsn from connection parameters.

Useful for display.
"""
function generate_dsn(params::ConnectionParameters)
    dsn_index = params.expand_dbname ? findfirst(params.keys, "dbname") : 0

    dsn = IOBuffer()
    if dsn_index > 0
        start_string = params.values[dsn_index]

        slash = '/'
        num_slashes = 0
        i = 0
        for i in eachindex(start_string)
            if start_string[i] == slash
                num_slashes += 1

                if num_slashes == 3
                    break
                end
            end
        end

        end_index = endof(start_string)

        print(dsn, start_string)

        if num_slashes < 2
            throw(PostgreSQLConnectionError("Invalid connection URI: $dsn"))
        elseif num_slashes < 3
            print(dsn, "/?")
        elseif i == end_index || !('?' in start_string[i+1:end_index])
            print(dsn, '?')
        end

        if start_string[end_index] != '?'
            # there is already a parameter in there
            print(dsn, '&')
        end
    else
        print(dsn, "postgresql:///?")
    end

    # now we're at the point where we can validly append parameters
    for i in eachindex(params.keys)
        if i != dsn_index
            print(dsn, params.keys[i])
            print(dsn, '=')
            print(dsn, params.values[i])
            print(dsn, '&')
        end
    end

    return takebuf_string(dsn)
end

end
