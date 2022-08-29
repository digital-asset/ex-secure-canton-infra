#!/bin/bash
# Copyright (c) 2022 Digital Asset (Switzerland) GmbH and/or its affiliates. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

set -e

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    CREATE USER participant1 ENCRYPTED PASSWORD 'Participant1Password!';
    CREATE DATABASE participant1;
    GRANT ALL PRIVILEGES ON DATABASE participant1 TO participant1;

    REVOKE ALL ON SCHEMA public FROM public;
EOSQL

echo "hostssl all all all scram-sha-256 clientcert=verify-full" >  $PGDATA/pg_hba.conf
#echo "hostnossl all all all scram-sha-256 " >  $PGDATA/pg_hba.conf
echo "hostnossl all postgres 0.0.0.0/0 reject" >> $PGDATA/pg_hba.conf
