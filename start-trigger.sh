#!/bin/bash
# Copyright (c) 2024 Digital Asset (Switzerland) GmbH and/or its affiliates. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

set -e

source env.sh

AUTH_TOKEN=`cat "certs/participant2/jwt/bob.token"`
./decode-jwt.sh "certs/participant2/jwt/bob.token"

BOB_PARTY=`cat data/parties.txt | jq .'bob' | tr -d '"'`

daml trigger --dar dars/SecureDaml.dar \
  --trigger-name BobTrigger:rejectTrigger \
  --ledger-host $PARTICIPANT_2_HOST --ledger-port $PARTICIPANT_2_PORT \
  --ledger-party $BOB_PARTY \
  --application-id "bob" \
  --access-token-file=./certs/participant2/jwt/bob.token \
  --tls \
  --cacrt ./certs/participant2/intermediate/certs/ca-chain.cert.pem \
  --pem ./certs/participant2/client/admin-api.customer2.com.key.pem \
  --crt ./certs/participant2/client/admin-api.customer2.com.cert.pem
