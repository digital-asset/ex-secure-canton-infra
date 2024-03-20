#!/bin/bash
# Copyright (c) 2024 Digital Asset (Switzerland) GmbH and/or its affiliates. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

# Documentation on JSON API
# https://docs.daml.com/json-api/index.html

source env.sh

DOMAIN=customer1.com
DOMAIN2=customer2.com

CURL_CERT_PARAM="--key $(pwd)/certs/participant1/client/admin-api.$DOMAIN.key.pem --cert $(pwd)/certs/participant1/client/admin-api.$DOMAIN.cert.pem "
CURL_CERT_PARAM2="--key $(pwd)/certs/participant2/client/admin-api.$DOMAIN2.key.pem --cert $(pwd)/certs/participant2/client/admin-api.$DOMAIN2.cert.pem "

AUTH_TOKEN=`cat "certs/participant1/jwt/navigator.token"`

echo ""
echo "Getting all current parties"
RESULT=`curl -s --cacert ./certs/participant1/intermediate/certs/ca-chain.cert.pem $CURL_CERT_PARAM \
  -X GET -H 'Content-Type: application/json' \
  -H "Authorization: Bearer $AUTH_TOKEN" \
  https://$JSON_API_1_HOST:$JSON_API_1_PORT/v1/parties`
echo $RESULT
echo $RESULT | jq .

echo ""
echo "Getting all current DAR packages"
RESULT=`curl -s --cacert ./certs/participant1/intermediate/certs/ca-chain.cert.pem $CURL_CERT_PARAM \
  -X GET -H 'Content-Type: application/json' \
  -H "Authorization: Bearer $AUTH_TOKEN" \
  https://$JSON_API_1_HOST:$JSON_API_1_PORT/v1/packages`
echo $RESULT | jq .

AUTH_TOKEN=`cat "certs/participant1/jwt/alice.token"`

echo ""
echo "Getting all current contracts for Alice"

RESULT=`curl -s --cacert ./certs/participant1/intermediate/certs/ca-chain.cert.pem $CURL_CERT_PARAM \
  -X GET -H 'Content-Type: application/json' \
  -H "Authorization: Bearer $AUTH_TOKEN" \
  https://$JSON_API_1_HOST:$JSON_API_1_PORT/v1/query`
echo $RESULT | jq .

AUTH_TOKEN=
RESULT=

ALICE_PARTY_ID=`cat data/parties.txt | jq .'alice' | tr -d '"'`
BOB_PARTY_ID=`cat data/parties.txt | jq .'bob' | tr -d '"'`
BANK_PARTY_ID=`cat data/parties.txt | jq .'bank' | tr -d '"'`

ALICE_AUTH_TOKEN=`cat "certs/participant1/jwt/alice.token"`
BOB_AUTH_TOKEN=`cat "certs/participant2/jwt/bob.token"`
BANK_AUTH_TOKEN=`cat "certs/participant2/jwt/bank.token"`

# Create a new Iou contract via JSON API
echo ""
echo "Creating new Iou contract"
RESULT=`curl -s --cacert ./certs/participant2/intermediate/certs/ca-chain.cert.pem $CURL_CERT_PARAM2 \
  -X POST -H 'Content-Type: application/json' \
  -H "Authorization: Bearer $BANK_AUTH_TOKEN" \
  -d "{ \"templateId\": \"Iou:Iou\", \"payload\": {\"owner\": \"$ALICE_PARTY_ID\", \"amount\": { \"value\": \"100\", \"currency\": \"USD\" }, \"payer\": \"$BANK_PARTY_ID\", \"viewers\": []}} " \
  https://$JSON_API_2_HOST:$JSON_API_2_PORT/v1/create`

echo $RESULT | jq .

STATUS=`echo $RESULT | jq .status `
if [ "$STATUS" != "200" ] ; then
  echo "ERROR: Failure executing command!"
  exit
fi
echo "Status: $STATUS"

IOU_CONTRACT_ID=`echo $RESULT | jq .result.contractId  | tr -d '"'`
echo "Contract ID: $IOU_CONTRACT_ID"

echo ""
echo "Create Paint offer"
RESULT=`curl -s --cacert ./certs/participant2/intermediate/certs/ca-chain.cert.pem $CURL_CERT_PARAM2 \
  -X POST -H 'Content-Type: application/json' \
  -H "Authorization: Bearer $BOB_AUTH_TOKEN" \
  -d "{ \"templateId\": \"Paint:OfferToPaintHouseByPainter\", \"payload\": {\"houseOwner\": \"$ALICE_PARTY_ID\", \"amount\": { \"value\": \"100\", \"currency\": \"USD\" }, \"bank\": \"$BANK_PARTY_ID\", \"painter\": \"$BOB_PARTY_ID\"}} " \
  https://$JSON_API_2_HOST:$JSON_API_2_PORT/v1/create`

echo $RESULT | jq .

STATUS=`echo $RESULT | jq .status `
if [ "$STATUS" != "200" ] ; then
  echo "ERROR: Failure executing command!"
  exit
fi
echo "Status: $STATUS"

PAINT_CONTRACT_ID=`echo $RESULT | jq .result.contractId  | tr -d '"'`
echo "Contract ID: $PAINT_CONTRACT_ID"


echo ""
echo "Exercise choice on Paint offer"
RESULT=`curl -s --cacert ./certs/participant1/intermediate/certs/ca-chain.cert.pem $CURL_CERT_PARAM \
  -X POST -H 'Content-Type: application/json' \
  -H "Authorization: Bearer $ALICE_AUTH_TOKEN" \
  -d "{ \"templateId\": \"Paint:OfferToPaintHouseByPainter\", \"contractId\": \"$PAINT_CONTRACT_ID\", \"user\": \"$ALICE_PARTY_ID\", \"choice\": \"AcceptByOwner\", \"argument\": { \"iouId\": \"$IOU_CONTRACT_ID\" } } " \
  https://$JSON_API_1_HOST:$JSON_API_1_PORT/v1/exercise`

echo $RESULT | jq .

STATUS=`echo $RESULT | jq .status `
if [ "$STATUS" != "200" ] ; then
  echo "ERROR: Failure executing command!"
  exit
fi
echo "Status: $STATUS"

ACCEPT_CONTRACT_ID=`echo $RESULT | jq .result.exerciseResult | tr -d '"'`
echo "Contract ID: $ACCEPT_CONTRACT_ID"

echo ""
echo "Exercise getCash choice"
RESULT=`curl -s --cacert ./certs/participant2/intermediate/certs/ca-chain.cert.pem $CURL_CERT_PARAM2 \
  -X POST -H 'Content-Type: application/json' \
  -H "Authorization: Bearer $BOB_AUTH_TOKEN" \
  -d "{ \"templateId\": \"Iou:Iou\", \"contractId\": \"$ACCEPT_CONTRACT_ID\", \"user\": \"$BOB_PARTY_ID\", \"choice\": \"Call\", \"argument\": {} } " \
  https://$JSON_API_2_HOST:$JSON_API_2_PORT/v1/exercise`

echo $RESULT | jq .

STATUS=`echo $RESULT | jq .status `
if [ "$STATUS" != "200" ] ; then
  echo "ERROR: Failure executing command!"
  exit
fi
echo "Status: $STATUS"

GETCASH_CONTRACT_ID=`echo $RESULT | jq .result.exerciseResult  | tr -d '"'`
echo "Contract ID: $GETCASH_CONTRACT_ID"




