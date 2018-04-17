# Testing Postgres Locally on OSX #

## Installing Postgres with correct Users ##

* `brew install postgresql`

* `pg_ctl start -D /usr/local/var/postgres`

* `createuser -s postgres`

* `psql -c 'create database julia_test;' -U postgres`

## Testing on v0.4 ##

In order to test on this version of Julia, `BaseTestNext` is required.
