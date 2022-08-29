#!/bin/bash
# Copyright (c) 2022 Digital Asset (Switzerland) GmbH and/or its affiliates. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

# https://prefetch.net/blog/2020/04/22/using-grpcurl-to-interact-with-grpc-applications/
# https://bionic.fullstory.com/tale-of-grpcurl/

source env.sh

CLIENT_CERT_AUTH=TRUE
DOMAIN=customer1.com

CLIENT_CERT_PARAM=""
CURL_CERT_PARAM=""
if [ "$CLIENT_CERT_AUTH" == "TRUE" ] ; then
  echo "Enabling Client Certificate Auth"
  CLIENT_CERT_PARAM="--pem $(pwd)/certs/participant1/client/admin-api.$DOMAIN.key.pem --crt $(pwd)/certs/participant1/client/admin-api.$DOMAIN.cert.pem "
  CURL_CERT_PARAM="--key $(pwd)/certs/participant1/client/admin-api.$DOMAIN.key.pem --cert $(pwd)/certs/participant1/client/admin-api.$DOMAIN.cert.pem "
fi

# Prove GRPC is up on TLS
echo "" 
echo "Get list of services via reflection"
JWT=`cat certs/participant1/jwt/participant_admin.token`

echo "" 
echo "Testing direct to Ledger..."
grpcurl -H "Authorization: Bearer $JWT" -cacert "$(pwd)/certs/participant1/intermediate/certs/ca-chain.cert.pem" $CURL_CERT_PARAM $PARTICIPANT_1_HOST:$PARTICIPANT_1_PORT list

echo ""
echo "Describe a service"
grpcurl -H "Authorization: Bearer $JWT" -cacert "$(pwd)/certs/participant1/intermediate/certs/ca-chain.cert.pem" $CURL_CERT_PARAM $PARTICIPANT_1_HOST:$PARTICIPANT_1_PORT describe com.daml.ledger.api.v1.LedgerConfigurationService

echo ""
echo "Describe a service"
grpcurl -H "Authorization: Bearer $JWT" -cacert "$(pwd)/certs/participant1/intermediate/certs/ca-chain.cert.pem" $CURL_CERT_PARAM $PARTICIPANT_1_HOST:$PARTICIPANT_1_PORT describe com.daml.ledger.api.v1.PackageService

 grpcurl -H "Authorization: Bearer $JWT" -cacert "$(pwd)/certs/participant1/intermediate/certs/ca-chain.cert.pem" $CURL_CERT_PARAM $PARTICIPANT_1_HOST:$PARTICIPANT_1_PORT describe com.daml.ledger.api.v1.ListPackagesRequest

echo ""
 grpcurl -H "Authorization: Bearer $JWT" -cacert "$(pwd)/certs/participant1/intermediate/certs/ca-chain.cert.pem" $CURL_CERT_PARAM $PARTICIPANT_1_HOST:$PARTICIPANT_1_PORT describe com.daml.ledger.api.v1.CommandService

 echo ""
 grpcurl -H "Authorization: Bearer $JWT" -cacert "$(pwd)/certs/participant1/intermediate/certs/ca-chain.cert.pem" $CURL_CERT_PARAM $PARTICIPANT_1_HOST:$PARTICIPANT_1_PORT describe com.daml.ledger.api.v1.CommandSubmissionService

grpcurl -H "Authorization: Bearer $JWT" -cacert "$(pwd)/certs/participant1/intermediate/certs/ca-chain.cert.pem" $CURL_CERT_PARAM $PARTICIPANT_1_HOST:$PARTICIPANT_1_PORT describe com.daml.ledger.api.v1.SubmitRequest

 grpcurl -H "Authorization: Bearer $JWT" -cacert "$(pwd)/certs/participant1/intermediate/certs/ca-chain.cert.pem" $CURL_CERT_PARAM $PARTICIPANT_1_HOST:$PARTICIPANT_1_PORT describe com.daml.ledger.api.v1.Commands




