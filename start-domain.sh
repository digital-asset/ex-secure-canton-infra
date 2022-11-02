#!/bin/bash

source env.sh

export POSTGRES_USER=domain
export POSTGRES_PASSWORD="DomainPassword!"
export POSTGRES_HOST=localhost
export POSTGRES_PORT=5432
export POSTGRES_MAX_CONNECTIONS=8

$CANTON_DIR/bin/canton $RUN_AS_DAEMON --log-file-name log/domain.log -c configs/mixins/api/public.conf -c configs/mixins/api/public-admin.conf -c configs/mixins/parameters/nonuck.conf -c configs/mixins/storage/postgres.conf -c configs/domain/domain.conf

