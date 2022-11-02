#!/bin/bash
# Copyright (c) 2022 Digital Asset (Switzerland) GmbH and/or its affiliates. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

source env.sh

get_os_type 
if  [[ ${_GET_OS_TYPE} =~ 'CYGWIN_NT' ]];then
  # Windows only supports a single postgres instance so all the TLS certs will be from the domain
  # for cygwin.  Create in the 'domain' pki
  echo "This script is not intended to be run in a Windows cygwin environment because it is assuemd there is a single, native windows postgres running."
  echo "This file is for Linux or MacOs where a postgres container is used.  Aborting ..."
fi

export DOMAIN=acme.com

docker stop domain-postgres > /dev/null 2>&1
docker rm domain-postgres > /dev/null 2>&1

docker run --name domain-postgres -d -p 5432:5432 \
  -e POSTGRES_PASSWORD="ChangeDefaultPassword!" \
  -e POSTGRES_HOST_AUTH_METHOD="scram-sha-256" \
  -e POSTGRES_INITDB_ARGS="--auth-host=scram-sha-256 --auth-local=scram-sha-256" \
  -v "$(pwd)/certs/domain/db/certs/db-chain.$DOMAIN.cert.pem:/var/lib/postgresql/db.$DOMAIN.cert.pem:ro" \
  -v "$(pwd)/certs/domain/db/private/db.$DOMAIN.key.pem:/var/lib/postgresql/db.$DOMAIN.key.pem:ro" \
  -v "$(pwd)/certs/domain/intermediate/certs/ca-chain.cert.pem:/var/lib/postgresql/ca-chain.crt:ro" \
  -v "$(pwd)/pg-initdb/domain:/docker-entrypoint-initdb.d:ro" \
  postgres:14 \
  -c ssl=on \
  -c ssl_cert_file=/var/lib/postgresql/db.$DOMAIN.cert.pem \
  -c ssl_key_file=/var/lib/postgresql/db.$DOMAIN.key.pem \
  -c ssl_ca_file=/var/lib/postgresql/ca-chain.crt \
  -c ssl_min_protocol_version="TLSv1.2" \
  -c ssl_ciphers="HIGH:!MEDIUM:+3DES:!aNULL"


