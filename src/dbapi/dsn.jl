module DSN

export is_valid_dsn, generate_dsn

import ..PostgreSQLDBAPIBase: ConnectionParameters,
    SimpleConnectionParameters,
    DSNConnectionParameters,
    PostgreSQLConnectionError

# this will catch at least a few errors in advance
const VALID_DSN = r"^postgres(ql)?://"

is_valid_dsn(dsn::ByteString) = ismatch(VALID_DSN, dsn)

function generate_dsn(params::DSNConnectionParameters)
    dsn = IOBuffer()

    dsn_param = params.values[1]
    nparams = length(params) - 1

    slash = '/'
    num_slashes = 0
    i = 0
    for i in eachindex(dsn_param)
        if dsn_param[i] == slash
            num_slashes += 1

            if num_slashes == 3
                break
            end
        end
    end

    if num_slashes < 2
        throw(PostgreSQLConnectionError("Invalid connection URI: $dsn"))
    end

    has_params_already = findnext(dsn_param, '=', i) > 0
    end_index = endof(dsn_param)

    print(dsn, dsn_param)

    if nparams > 0
        if has_params_already
            print(dsn, '&')
        else
            # we have to make sure the first part of the dsn is properly terminated
            if num_slashes == 2
                print(dsn, "/?")
            else
                print(dsn, '?')
            end
        end

        # leave out the dsn in dbname (always first parameter)
        for i = 2:(nparams - 1)
            print_param(dsn, params, i)

            print(dsn, '&')
        end

        print_param(dsn, params, nparams + 1)  # make sure to print the actual last
    end

    return takebuf_string(dsn)
end

function generate_dsn(params::SimpleConnectionParameters)
    dsn = IOBuffer()

    nparams = length(params)

    print(dsn, "postgresql:///")

    if nparams > 0
        print(dsn, '?')

        for i = 1:(nparams - 1)
            print_param(dsn, params, i)

            print(dsn, '&')
        end

        print_param(dsn, params, nparams)
    end

    return takebuf_string(dsn)
end

function print_param(io::IO, params::ConnectionParameters, index::Int)
    print(io, params.keys[index])
    print(io, '=')
    print(io, params.values[index])
end

"""
Generates a dsn from connection parameters.

Useful for display.
"""
generate_dsn

end
