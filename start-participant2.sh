#!/bin/bash
# Copyright (c) 2022 Digital Asset (Switzerland) GmbH and/or its affiliates. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

source env.sh

export POSTGRES_USER=participant2
export POSTGRES_PASSWORD=Participant2Password!
export POSTGRES_HOST=localhost
export POSTGRES_PORT=5434
export POSTGRES_MAX_CONNECTIONS=8

export POSTGRES_SSL=true
export POSTGRES_SSLMODE=verify-full
export POSTGRES_SSLROOTCERT="certs/participant2/intermediate/certs/ca-chain.cert.pem"
export POSTGRES_SSLCERT="certs/participant2/client/participant2.customer2.com.cert.der"
export POSTGRES_SSLKEY="certs/participant2/client/participant2.customer2.com.key.der"
export POSTGRES_URL="jdbc:postgresql://$POSTGRES_HOST:$POSTGRES_PORT/participant2?user=participant2&password=Participant2Password!&ssl=true&sslmode=verify-full&sslrootcert=$ROOTDIR/certs/participant2/intermediate/certs/ca-chain.cert.pem&sslcert=$ROOTDIR/certs/participant2/client/participant2.customer2.com.cert.der&sslkey=$ROOTDIR/certs/participant2/client/participant2.customer2.com.key.der"

export JWKS_URL="file://${ROOTDIR}/certs/participant2/jwt/jwks.json"

export PARTICIPANT_TOKEN=`cat certs/participant2/jwt/participant_admin.token`

$CANTON_DIR/bin/canton $RUN_AS_DAEMON --log-file-name log/participant2.log -c configs/mixins/api/jwt/jwks.conf -c configs/mixins/api/public.conf -c configs/mixins/api/public-admin.conf -c configs/mixins/parameters/nonuck.conf -c configs/mixins/storage/postgres.conf -c configs/participant/participant2.conf --bootstrap configs/participant/participant-init.canton
