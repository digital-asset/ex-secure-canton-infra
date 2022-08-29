#!/bin/bash
# Copyright (c) 2022 Digital Asset (Switzerland) GmbH and/or its affiliates. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

set -e

source env.sh

# Start Navigator Server

daml navigator server \
  --cacrt certs/participant1/intermediate/certs/ca-chain.cert.pem \
  --tls --pem certs/participant1/client/admin-api.customer1.com.key.pem --crt certs/participant1/client/admin-api.customer1.com.cert.pem \
  --access-token-file certs/participant1/jwt/navigator.token \
  $PARTICIPANT_1_HOST $PARTICIPANT_1_PORT
