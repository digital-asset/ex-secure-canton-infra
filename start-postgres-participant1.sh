#!/bin/bash
# Copyright (c) 2022 Digital Asset (Switzerland) GmbH and/or its affiliates. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

source env.sh

export DOMAIN=customer1.com

docker stop participant1-postgres > /dev/null 2>&1
docker rm participant1-postgres > /dev/null 2>&1

docker run --name participant1-postgres -d -p 5433:5432 \
  -e POSTGRES_PASSWORD="ChangeDefaultPassword!" \
  -e POSTGRES_HOST_AUTH_METHOD="scram-sha-256" \
  -e POSTGRES_INITDB_ARGS="--auth-host=scram-sha-256 --auth-local=scram-sha-256" \
  -v "$(pwd)/certs/participant1/db/certs/db-chain.$DOMAIN.cert.pem:/var/lib/postgresql/db.$DOMAIN.cert.pem:ro" \
  -v "$(pwd)/certs/participant1/db/private/db.$DOMAIN.key.pem:/var/lib/postgresql/db.$DOMAIN.key.pem:ro" \
  -v "$(pwd)/certs/participant1/intermediate/certs/ca-chain.cert.pem:/var/lib/postgresql/ca-chain.crt:ro" \
  -v "$(pwd)/pg-initdb/participant1:/docker-entrypoint-initdb.d:ro" \
  postgres:14 \
  -c ssl=on \
  -c ssl_cert_file=/var/lib/postgresql/db.$DOMAIN.cert.pem \
  -c ssl_key_file=/var/lib/postgresql/db.$DOMAIN.key.pem \
  -c ssl_ca_file=/var/lib/postgresql/ca-chain.crt \
  -c ssl_min_protocol_version="TLSv1.2" \
  -c ssl_ciphers="HIGH:!MEDIUM:+3DES:!aNULL"


