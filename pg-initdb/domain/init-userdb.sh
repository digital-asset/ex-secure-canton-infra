#!/bin/bash
# Copyright (c) 2022 Digital Asset (Switzerland) GmbH and/or its affiliates. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

set -e

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    CREATE USER domain ENCRYPTED PASSWORD 'DomainPassword!';
    CREATE DATABASE domain;
    GRANT ALL PRIVILEGES ON DATABASE domain TO domain;

    CREATE USER mediator ENCRYPTED PASSWORD 'MediatorPassword!';
    CREATE DATABASE mediator;
    GRANT ALL PRIVILEGES ON DATABASE mediator TO mediator;

    CREATE USER sequencer ENCRYPTED PASSWORD 'SequencerPassword!';
    CREATE DATABASE sequencer;
    GRANT ALL PRIVILEGES ON DATABASE sequencer TO sequencer;

    REVOKE ALL ON SCHEMA public FROM public;
EOSQL

echo "hostssl all all all scram-sha-256 clientcert=verify-full" >  $PGDATA/pg_hba.conf
echo "hostnossl all postgres 0.0.0.0/0 reject" >> $PGDATA/pg_hba.conf
