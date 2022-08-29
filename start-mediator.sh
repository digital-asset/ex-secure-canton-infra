#!/bin/bash

source env.sh

export POSTGRES_USER=mediator
export POSTGRES_PASSWORD=MediatorPassword!
export POSTGRES_HOST=localhost
export POSTGRES_PORT=5432
export POSTGRES_MAX_CONNECTIONS=8

# Note that SSL Client cert CN has to match Postgres login name
export POSTGRES_SSL=true
export POSTGRES_SSLMODE=verify-full
export POSTGRES_SSLROOTCERT="certs/domain/intermediate/certs/ca-chain.cert.pem"
export POSTGRES_SSLCERT="certs/domain/client/mediator.acme.com.cert.der"
export POSTGRES_SSLKEY="certs/domain/client/mediator.acme.com.key.der"

$CANTON_DIR/bin/canton $RUN_AS_DAEMON --log-file-name log/mediator.log -c configs/mixins/api/public.conf -c configs/mixins/api/public-admin.conf -c configs/mixins/parameters/nonuck.conf -c configs/mixins/storage/postgres.conf -c configs/domain/mediator.conf
