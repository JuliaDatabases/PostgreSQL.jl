facts("DSN") do
    ConnectionParameters = PostgreSQL.PostgreSQLDBAPI.PostgreSQLDBAPIBase.ConnectionParameters
    DSNConnectionParameters = PostgreSQL.PostgreSQLDBAPI.PostgreSQLDBAPIBase.DSNConnectionParameters
    generate_dsn = PostgreSQL.PostgreSQLDBAPI.DSN.generate_dsn
    PostgreSQLConnectionError = PostgreSQL.PostgreSQLDBAPI.PostgreSQLDBAPIBase.PostgreSQLConnectionError

    context("Invalid") do
        dsn = "postgresql:/"
        params = DSNConnectionParameters(["dbname"], [dsn], dsn)
        @fact_throws PostgreSQLConnectionError generate_dsn(params)

        dsn = ""
        params = DSNConnectionParameters(["dbname"], [dsn], dsn)
        @fact_throws PostgreSQLConnectionError generate_dsn(params)
    end

    context("Expand DBNAME") do
        dsn = "postgresql://postgres@localhost:5432"

        # it should only expand the first dbname
        context("No expanding") do
            params = ConnectionParameters("postgresql://"; dbname=dsn)
            generated_dsn = generate_dsn(params)
            @fact generated_dsn --> "postgresql:///?dbname=$dsn"
        end

        context("Expanding") do
            params = ConnectionParameters(dsn)
            generated_dsn = generate_dsn(params)
            @fact generated_dsn --> dsn
        end
    end

    context("No DSN") do
        context("No parameters") do
            params = ConnectionParameters()
            generated_dsn = generate_dsn(params)
            @fact generated_dsn --> "postgresql:///"
        end

        context("One parameter") do
            params = ConnectionParameters(; host="localhost")
            generated_dsn = generate_dsn(params)
            @fact generated_dsn --> "postgresql:///?host=localhost"
        end

        context("Two parameters") do
            params = ConnectionParameters(; host="localhost", port="5432")
            generated_dsn = generate_dsn(params)
            @fact generated_dsn --> "postgresql:///?host=localhost&port=5432"
        end

        context("Three parameters") do
            params = ConnectionParameters(; host="localhost", port="5432", user="postgres")
            generated_dsn = generate_dsn(params)
            @fact generated_dsn --> "postgresql:///?host=localhost&port=5432&user=postgres"
        end
    end

    context("Has DSN") do
        context("No parameters") do
            context("Two slashes") do
                dsn = "postgresql://postgres@localhost:5432"
                params = ConnectionParameters(dsn)
                generated_dsn = generate_dsn(params)
                @fact generated_dsn --> dsn
            end

            context("Three slashes") do
                dsn = "postgresql://postgres@localhost:5432/postgres?host=localhost"
                params = ConnectionParameters(dsn)
                generated_dsn = generate_dsn(params)
                @fact generated_dsn --> "$dsn"
            end

            context("Trailing &") do
                dsn = "postgresql://postgres@localhost:5432/postgres?host=localhost&"
                params = ConnectionParameters(dsn)
                generated_dsn = generate_dsn(params)
                @fact generated_dsn --> "$dsn"
            end
        end

        context("Has parameters") do
            context("No &") do
                dsn = "postgresql://postgres@localhost:5432/postgres"
                params = ConnectionParameters(dsn; host="localhost")
                generated_dsn = generate_dsn(params)
                @fact generated_dsn --> "$(dsn)host=localhost"
            end

            context("Trailing &") do
                dsn = "postgresql://postgres@localhost:5432/postgres?host=localhost&"
                params = ConnectionParameters(dsn; host="localhost")
                generated_dsn = generate_dsn(params)
                @fact generated_dsn --> "$(dsn)host=localhost"
            end

            context("One parameter") do
                dsn = "postgresql://postgres@localhost:5432/postgres?host=localhost"
                params = ConnectionParameters(dsn; host="localhost")
                generated_dsn = generate_dsn(params)
                @fact generated_dsn --> "$dsn&host=localhost"
            end

            context("Two parameters") do
                dsn = "postgresql://postgres@localhost:5432/postgres?host=localhost"
                params = ConnectionParameters(dsn; host="localhost", dbname="postgres")
                generated_dsn = generate_dsn(params)
                @fact generated_dsn --> "$dsn&host=localhost&dbname=postgres"
            end

            context("Three parameters") do
                dsn = "postgresql://postgres@localhost:5432/postgres?host=localhost"
                params = ConnectionParameters(dsn; host="localhost", dbname="postgres", port="5432")
                generated_dsn = generate_dsn(params)
                @fact generated_dsn --> "$dsn&host=localhost&dbname=postgres&port=5432"
            end
        end
    end
end
