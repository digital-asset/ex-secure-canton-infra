#!/bin/bash
# Copyright (c) 2024 Digital Asset (Switzerland) GmbH and/or its affiliates. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

set -e

source env.sh

DOMAIN=customer1.com

# Start JSON API Server

daml json-api --log-level info \
  --ledger-host $PARTICIPANT_1_HOST --ledger-port $PARTICIPANT_1_PORT \
  --address 0.0.0.0 --http-port=$JSON_API_1A_PORT \
  --max-inbound-message-size 4194304 \
  --package-reload-interval 5s \
  --cacrt certs/participant1/intermediate/certs/ca-chain.cert.pem \
  --crt certs/participant1/client/admin-api.customer1.com.cert.pem \
  --pem certs/participant1/client/admin-api.customer1.com.key.pem 
