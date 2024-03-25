#!/bin/bash
# Copyright (c) 2024 Digital Asset (Switzerland) GmbH and/or its affiliates. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

source env.sh

export POSTGRES_USER=participant1
export POSTGRES_PASSWORD=Participant1Password!
export POSTGRES_HOST=localhost
export POSTGRES_PORT=5433
export POSTGRES_MAX_CONNECTIONS=8

export POSTGRES_SSL=true
export POSTGRES_SSLMODE=verify-full
export POSTGRES_SSLROOTCERT="certs/participant1/intermediate/certs/ca-chain.cert.pem"
export POSTGRES_SSLCERT="certs/participant1/client/participant1.customer1.com.cert.der"
export POSTGRES_SSLKEY="certs/participant1/client/participant1.customer1.com.key.der"
export POSTGRES_URL="jdbc:postgresql://$POSTGRES_HOST:$POSTGRES_PORT/participant1?user=participant1&password=Participant1Password!&ssl=true&sslmode=verify-full&sslrootcert=$ROOTDIR/certs/participant1/intermediate/certs/ca-chain.cert.pem&sslcert=$ROOTDIR/certs/participant1/client/participant1.customer1.com.cert.der&sslkey=$ROOTDIR/certs/participant1/client/participant1.customer1.com.key.der"

export JWKS_URL="file://${ROOTDIR}/certs/participant1/jwt/jwks.json"

export PARTICIPANT_TOKEN=`cat certs/participant1/jwt/participant_admin.token`

$CANTON_DIR/bin/canton $RUN_AS_DAEMON --log-file-name log/participant1b.log -c configs/mixins/api/jwt/jwks.conf -c configs/mixins/api/public.conf -c configs/mixins/api/public-admin.conf -c configs/mixins/parameters/nonuck.conf -c configs/mixins/storage/postgres.conf -c configs/participant/participant1b.conf --bootstrap configs/participant/participant-init.canton
