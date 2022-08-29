#!/bin/bash
# Copyright (c) 2022 Digital Asset (Switzerland) GmbH and/or its affiliates. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

source env.sh

namespace=$1
DOMAIN=$2
LEDGER_ID=123456789

# Parameters
# 1 - signing private key
# 2 - JWKS token
# 3 - Service Accounts JSON Lookup
# 4 - Ledger ID
# 5 - TLS private key
# 6 - TLS Public chain
python3 auth-service.py "./certs/$namespace/signing/jwt-sign.$DOMAIN.key.pem" ./certs/$namespace/jwt/jwks.json "./accounts-$namespace.json" $LEDGER_ID "./certs/$namespace/auth/private/auth.$DOMAIN.key.pem" "./certs/$namespace/auth/certs/auth-chain.$DOMAIN.cert.pem"
