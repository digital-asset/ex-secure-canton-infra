#!/bin/bash
# Copyright (c) 2020 Digital Asset (Switzerland) GmbH and/or its affiliates. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

source env.sh

GEORGE_CLIENT_ID="george123456"
#GEORGE_CLIENT_SECRET=`cat accounts.json | jq ."$GEORGE_CLIENT_ID".secret  | tr -d '"'`
GEORGE_CLIENT_SECRET=`cat accounts.json| jq -c ".[] | select (.client_id | contains(\"george123456\") ) " | jq .client_secret | tr -d '"'`

GEORGE_PARTY=`cat data/parties.txt | jq .'george' | tr -d '"'`

python3 bot/bot.py \
 "$GEORGE_PARTY" \
 "$GEORGE_PARTY" \
 "https://$PARTICIPANT_2_HOST:$PARTICIPANT_2_PORT" \
 "./certs/participant2/intermediate/certs/ca-chain.cert.pem" \
 "./certs/participant2/client/admin-api.customer2.com.cert.pem" \
 "./certs/participant2/client/admin-api.customer2.com.key.pem" \
 $GEORGE_CLIENT_ID \
 $GEORGE_CLIENT_SECRET \
 "https://$JWTISSUER_2_HOST:$JWTISSUER_2_PORT/auth" \
 "./certs/participant2/intermediate/certs/ca-chain.cert.pem" \
 "https://daml.com/ledger-api"
