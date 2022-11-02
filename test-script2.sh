#!/bin/bash
# Copyright (c) 2020 Digital Asset (Switzerland) GmbH and/or its affiliates. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

source env.sh

#./decode-jwt.sh "${ROOTDIR}/certs/participant1/jwt/participant_admin.token"
#./decode-jwt.sh "${ROOTDIR}/certs/participant1/jwt/navigator.token"
#./decode-jwt.sh "${ROOTDIR}/certs/participant1/jwt/alice.token"

#./decode-jwt.sh "${ROOTDIR}/certs/participant2/jwt/participant_admin.token"
#./decode-jwt.sh "${ROOTDIR}/certs/participant2/jwt/navigator.token"
#./decode-jwt.sh "${ROOTDIR}/certs/participant2/jwt/bob.token"
#./decode-jwt.sh "${ROOTDIR}/certs/participant2/jwt/bank.token"
#./decode-jwt.sh "${ROOTDIR}/certs/participant2/jwt/george.token"


daml script --dar dars/SecureDaml.dar \
  --script-name Workflow:configDonorP1 \
  --ledger-host $PARTICIPANT_1_HOST --ledger-port $PARTICIPANT_1_PORT \
  --access-token-file=./certs/participant1/jwt/navigator.token \
  --application-id "ex-secure-daml-infra" \
  --tls \
  --cacrt ./certs/participant1/intermediate/certs/ca-chain.cert.pem \
  --pem ./certs/participant1/client/admin-api.customer1.com.key.pem \
  --crt ./certs/participant1/client/admin-api.customer1.com.cert.pem \
  --input-file data/parties.txt

daml script --dar dars/SecureDaml.dar \
  --script-name Workflow:configDonorP2 \
  --ledger-host $PARTICIPANT_2_HOST --ledger-port $PARTICIPANT_2_PORT \
  --access-token-file=./certs/participant2/jwt/navigator.token \
  --application-id "ex-secure-daml-infra" \
  --tls \
  --cacrt ./certs/participant2/intermediate/certs/ca-chain.cert.pem \
  --pem ./certs/participant2/client/admin-api.customer2.com.key.pem \
  --crt ./certs/participant2/client/admin-api.customer2.com.cert.pem \
  --input-file data/parties.txt

daml script --dar dars/SecureDaml.dar \
  --script-name Workflow:allocateAssetP1 \
  --ledger-host $PARTICIPANT_1_HOST --ledger-port $PARTICIPANT_1_PORT \
  --access-token-file=./certs/participant1/jwt/alice.token \
  --application-id "alice" \
  --tls \
  --cacrt ./certs/participant1/intermediate/certs/ca-chain.cert.pem \
  --pem ./certs/participant1/client/admin-api.customer1.com.key.pem \
  --crt ./certs/participant1/client/admin-api.customer1.com.cert.pem \
  --input-file data/parties.txt

daml script --dar dars/SecureDaml.dar \
  --script-name Workflow:allocateAssetP2 \
  --ledger-host $PARTICIPANT_2_HOST --ledger-port $PARTICIPANT_2_PORT \
  --access-token-file=./certs/participant2/jwt/bob.token \
  --application-id "bob" \
  --tls \
  --cacrt ./certs/participant2/intermediate/certs/ca-chain.cert.pem \
  --pem ./certs/participant2/client/admin-api.customer2.com.key.pem \
  --crt ./certs/participant2/client/admin-api.customer2.com.cert.pem \
  --input-file data/parties.txt

daml script --dar dars/SecureDaml.dar \
  --script-name Workflow:testAsset \
  --ledger-host $PARTICIPANT_1_HOST --ledger-port $PARTICIPANT_1_PORT \
  --access-token-file=./certs/participant1/jwt/alice.token \
  --application-id "alice" \
  --tls \
  --cacrt ./certs/participant1/intermediate/certs/ca-chain.cert.pem \
  --pem ./certs/participant1/client/admin-api.customer1.com.key.pem \
  --crt ./certs/participant1/client/admin-api.customer1.com.cert.pem \
  --input-file data/parties.txt

