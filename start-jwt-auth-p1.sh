#!/bin/bash
# Copyright (c) 2024 Digital Asset (Switzerland) GmbH and/or its affiliates. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

source env.sh

namespace=$1
DOMAIN=$2

if [[ "$namespace" == "participant1" ]] ; then
   JWTISSUER_PORT=$JWTISSUER_1_PORT
else
   JWTISSUER_PORT=$JWTISSUER_2_PORT
fi

# Parameters
# 1 - signing private key
# 2 - JWKS token
# 3 - Service Accounts JSON Lookup
# 4 - Auth Port
# 5 - Ledger ID
# 6 - TLS private key
# 7 - TLS Public chain
python3 jwt-auth-service.py \
   "./certs/$namespace/signing/jwt-sign.$DOMAIN.key.pem" \
   "./certs/$namespace/signing/jwt-sign.$DOMAIN.cert.pem" \
   "./certs/$namespace/intermediate/certs/ca-chain.$DOMAIN.cert.pem" \
   "./certs/$namespace/auth/private/auth.$DOMAIN.key.pem" \
   "./certs/$namespace/auth/certs/auth-chain.$DOMAIN.cert.pem" \
   "./default_accounts.json" \
   $JWTISSUER_PORT \
   $namespace \
   "./data/p1-user-auth.json"




