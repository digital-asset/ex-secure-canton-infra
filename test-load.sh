#!/bin/bash
# Copyright (c) 2020 Digital Asset (Switzerland) GmbH and/or its affiliates. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

# Documentation on JSON API
# https://docs.daml.com/json-api/index.html

source env.sh

# Set the following to the user token
# UPDATE THE FOLLOWING
#
AUTH_TOKEN_NAME="george.token"
PARTY_ID=`cat data/parties.txt | jq ."george"`
#AUTH_TOKEN_NAME="bob.token"
#PARTY_ID=`cat data/parties.txt | jq ."bob"`

if [ ! -f "certs/participant2/jwt/$AUTH_TOKEN_NAME" ] ; then
  echo "ERROR: Please set user authentication up first!"
  exit 1
fi

AUTH_TOKEN=`cat "certs/participant2/jwt/$AUTH_TOKEN_NAME"`

DOMAIN=customer2.com

# Tests
# Create a new Asset for Party
# Move Asset to new owner

create_asset() {
  # Create a new contract via JSON API
  echo ""
  echo "Creating new contract"
  RANDOM_STRING=`openssl rand -hex 16`
  RESULT=`curl -s --cacert ./certs/participant2/intermediate/certs/ca-chain.cert.pem --key $(pwd)/certs/participant2/client/admin-api.$DOMAIN.key.pem --cert $(pwd)/certs/participant2/client/admin-api.$DOMAIN.cert.pem -X POST -H 'Content-Type: application/json' -H "Authorization: Bearer $AUTH_TOKEN" -d "{ \"templateId\": \"Main:Asset\", \"payload\": {\"owner\": $PARTY_ID,\"name\": \"TV-$RANDOM_STRING\", \"issuer\": $PARTY_ID}}" https://$JSON_API_2_HOST:$JSON_API_2_PORT/v1/create`
  #RESULT=`curl -s -X POST -H 'Content-Type: application/json' -H "Authorization: Bearer $AUTH_TOKEN" -d "{ \"templateId\": \"Main:Asset\", \"payload\": {\"owner\": $PARTY_ID,\"name\": \"TV-$RANDOM_STRING\", \"issuer\": $PARTY_ID}}" http://$JSON_API_2_HOST:$JSON_API_2_PORT/v1/create`

  #echo $RESULT | jq .

  STATUS=`echo $RESULT | jq .status `
  if [ "$STATUS" != "200" ] ; then
    echo "ERROR: Failure executing command!"
    exit
  fi
  echo "Status: $STATUS"

  CONTRACT_ID=`echo $RESULT | jq .result.contractId  | tr -d '"'`
  echo "Contract ID: $CONTRACT_ID"
}


for i in {0..1000}
do
  create_asset
done

