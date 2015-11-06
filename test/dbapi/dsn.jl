facts("DSN") do
    ConnectionParameters = PostgreSQL.PostgreSQLDBAPI.PostgreSQLDBAPIBase.ConnectionParameters
    generate_dsn = PostgreSQL.PostgreSQLDBAPI.DSN.generate_dsn

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
