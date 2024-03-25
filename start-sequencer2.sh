#!/bin/bash
# Copyright (c) 2024 Digital Asset (Switzerland) GmbH and/or its affiliates. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

source env.sh

export POSTGRES_USER=sequencer
export POSTGRES_PASSWORD=SequencerPassword!
export POSTGRES_HOST=localhost
export POSTGRES_PORT=5432
export POSTGRES_MAX_CONNECTIONS=8

export POSTGRES_SSL=true
export POSTGRES_SSLMODE=verify-full
export POSTGRES_SSLROOTCERT="certs/domain/intermediate/certs/ca-chain.cert.pem"
export POSTGRES_SSLCERT="certs/domain/client/sequencer.acme.com.cert.der"
export POSTGRES_SSLKEY="certs/domain/client/sequencer.acme.com.key.der"

$CANTON_DIR/bin/canton  $RUN_AS_DAEMON --log-file-name log/sequencer2.log -c configs/mixins/api/public.conf -c configs/mixins/api/public-admin.conf -c configs/mixins/parameters/nonuck.conf -c configs/mixins/storage/postgres.conf -c configs/domain/sequencer2.conf
