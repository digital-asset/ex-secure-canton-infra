#!/bin/bash
# Copyright (c) 2024 Digital Asset (Switzerland) GmbH and/or its affiliates. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

set -e

source env.sh

DOMAIN=customer2.com

# Start JSON API Server

daml json-api --log-level info \
  --ledger-host $PARTICIPANT_2_HOST --ledger-port $PARTICIPANT_2_PORT \
  --address 0.0.0.0 --http-port=$JSON_API_2A_PORT \
  --max-inbound-message-size 4194304 \
  --package-reload-interval 5s \
  --cacrt certs/participant2/intermediate/certs/ca-chain.cert.pem \
  --crt certs/participant2/client/admin-api.customer2.com.cert.pem \
  --pem certs/participant2/client/admin-api.customer2.com.key.pem \
