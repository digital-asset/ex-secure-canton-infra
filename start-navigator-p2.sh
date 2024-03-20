#!/bin/bash
# Copyright (c) 2024 Digital Asset (Switzerland) GmbH and/or its affiliates. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

set -e

source env.sh

# Start Navigator Server

daml navigator server \
  --cacrt certs/participant2/intermediate/certs/ca-chain.cert.pem \
  --tls --pem certs/participant2/client/admin-api.customer2.com.key.pem --crt certs/participant2/client/admin-api.customer2.com.cert.pem \
  --port 4001 \
  --access-token-file certs/participant2/jwt/navigator.token \
  $PARTICIPANT_2_HOST $PARTICIPANT_2_PORT
