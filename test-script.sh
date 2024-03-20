#!/bin/bash
# Copyright (c) 2024 Digital Asset (Switzerland) GmbH and/or its affiliates. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

source env.sh

get-participants() {
  local namespace=$1
  local hostname=$2
  local port=$3
  local DOMAIN=$4

  CLIENT_CERT_AUTH=TRUE
  CLIENT_CERT_PARAM=""
  CURL_CERT_PARAM=""
  if [ "$CLIENT_CERT_AUTH" == "TRUE" ] ; then
    echo "Enabling Client Certificate Auth"
    CLIENT_CERT_PARAM="--pem ${ROOTDIR}/certs/$namespace/client/admin-api.$DOMAIN.key.pem --crt ${ROOTDIR}/certs/$namespace/client/admin-api.$DOMAIN.cert.pem "
    CURL_CERT_PARAM="--key ${ROOTDIR}/certs/$namespace/client/admin-api.$DOMAIN.key.pem --cert ${ROOTDIR}/certs/$namespace/client/admin-api.$DOMAIN.cert.pem "
  fi

  AUTH_TOKEN=`cat "${ROOTDIR}/certs/$namespace/jwt/participant_admin.token"`
  ./decode-jwt.sh "${ROOTDIR}/certs/$namespace/jwt/participant_admin.token"

  daml script --dar ./dars/SecureDaml.dar \
    --script-name Setup:listParties \
    --ledger-host $hostname --ledger-port $port \
    --access-token-file=${ROOTDIR}/certs/$namespace/jwt/participant_admin.token \
    --application-id "ex-secure-canton-infra" \
    --tls $CLIENT_CERT_PARAM \
    --cacrt "${ROOTDIR}/certs/$namespace/intermediate/certs/ca-chain.cert.pem" \
    --output-file ./data/participants.txt
}

setup-participant() {
  local namespace=$1
  local hostname=$2
  local port=$3
  local DOMAIN=$4

  CLIENT_CERT_AUTH=TRUE
  CLIENT_CERT_PARAM=""
  CURL_CERT_PARAM=""
  if [ "$CLIENT_CERT_AUTH" == "TRUE" ] ; then
    echo "Enabling Client Certificate Auth"
    CLIENT_CERT_PARAM="--pem ${ROOTDIR}/certs/$namespace/client/admin-api.$DOMAIN.key.pem --crt ${ROOTDIR}/certs/$namespace/client/admin-api.$DOMAIN.cert.pem "
    CURL_CERT_PARAM="--key ${ROOTDIR}/certs/$namespace/client/admin-api.$DOMAIN.key.pem --cert ${ROOTDIR}/certs/$namespace/client/admin-api.$DOMAIN.cert.pem "
  fi

  AUTH_TOKEN=`cat "${ROOTDIR}/certs/$namespace/jwt/participant_admin.token"`
  ./decode-jwt.sh "${ROOTDIR}/certs/$namespace/jwt/participant_admin.token"

  echo ""
  echo "Getting all current parties"
  RESULT=`grpcurl -H "Authorization: Bearer $AUTH_TOKEN" -cacert "${ROOTDIR}/certs/$namespace/intermediate/certs/ca-chain.cert.pem" $CURL_CERT_PARAM $hostname:$port com.daml.ledger.api.v1.admin.UserManagementService/ListUsers`
  echo "Users:: $RESULT "
  RESULT=`grpcurl -H "Authorization: Bearer $AUTH_TOKEN" -cacert "${ROOTDIR}/certs/$namespace/intermediate/certs/ca-chain.cert.pem" $CURL_CERT_PARAM $hostname:$port com.daml.ledger.api.v1.admin.PartyManagementService/ListKnownParties`
  echo "Parties: $RESULT "

  daml script --dar ./dars/SecureDaml.dar \
    --script-name Setup:setup_$namespace \
    --ledger-host $hostname --ledger-port $port \
    --access-token-file=${ROOTDIR}/certs/$namespace/jwt/participant_admin.token \
    --application-id "ex-secure-canton-infra" \
    --tls $CLIENT_CERT_PARAM \
    --cacrt "${ROOTDIR}/certs/$namespace/intermediate/certs/ca-chain.cert.pem" \
    --output-file ./data/script-output-$namespace.txt

#  cat logs/script-output-$namespace.txt
  RESULT=`grpcurl -H "Authorization: Bearer $AUTH_TOKEN" -cacert "${ROOTDIR}/certs/$namespace/intermediate/certs/ca-chain.cert.pem" $CURL_CERT_PARAM $hostname:$port com.daml.ledger.api.v1.admin.UserManagementService/ListUsers`
  echo "Users:: $RESULT "
  RESULT=`grpcurl -H "Authorization: Bearer $AUTH_TOKEN" -cacert "${ROOTDIR}/certs/$namespace/intermediate/certs/ca-chain.cert.pem" $CURL_CERT_PARAM $hostname:$port com.daml.ledger.api.v1.admin.PartyManagementService/ListKnownParties`
  echo "Parties: $RESULT "

}

test_workflow() {

  daml ledger upload-dar \
    --host=$PARTICIPANT_1_HOST --port=$PARTICIPANT_1_PORT \
    --access-token-file=${ROOTDIR}/certs/participant1/jwt/participant_admin.token \
    --tls --pem ${ROOTDIR}/certs/participant1/client/admin-api.customer1.com.key.pem \
    --crt ${ROOTDIR}/certs/participant1/client/admin-api.customer1.com.cert.pem \
    --cacrt "${ROOTDIR}/certs/participant1/intermediate/certs/ca-chain.cert.pem" \
    dars/SecureDaml.dar 

  daml ledger upload-dar \
    --host=$PARTICIPANT_2_HOST --port=$PARTICIPANT_2_PORT \
    --access-token-file=${ROOTDIR}/certs/participant2/jwt/participant_admin.token \
    --tls --pem ${ROOTDIR}/certs/participant2/client/admin-api.customer2.com.key.pem \
    --crt ${ROOTDIR}/certs/participant2/client/admin-api.customer2.com.cert.pem \
    --cacrt "${ROOTDIR}/certs/participant2/intermediate/certs/ca-chain.cert.pem" \
    dars/SecureDaml.dar 

  daml script --dar ./dars/SecureDaml.dar \
    --script-name Workflow:bankIou \
    --ledger-host $PARTICIPANT_2_HOST --ledger-port $PARTICIPANT_2_PORT \
    --access-token-file=${ROOTDIR}/certs/participant2/jwt/bank.token \
    --application-id "bank" \
    --tls --pem ${ROOTDIR}/certs/participant2/client/admin-api.customer2.com.key.pem \
    --crt ${ROOTDIR}/certs/participant2/client/admin-api.customer2.com.cert.pem \
    --cacrt "${ROOTDIR}/certs/participant2/intermediate/certs/ca-chain.cert.pem" \
    --input-file ./data/parties.txt \
    --output-file ./data/iou_contract.txt

  daml script --dar ./dars/SecureDaml.dar \
    --script-name Workflow:paintOffer \
    --ledger-host $PARTICIPANT_2_HOST --ledger-port $PARTICIPANT_2_PORT \
    --access-token-file=${ROOTDIR}/certs/participant2/jwt/bob.token \
    --application-id "bob" \
    --tls --pem ${ROOTDIR}/certs/participant2/client/admin-api.customer2.com.key.pem \
    --crt ${ROOTDIR}/certs/participant2/client/admin-api.customer2.com.cert.pem \
    --cacrt "${ROOTDIR}/certs/participant2/intermediate/certs/ca-chain.cert.pem" \
    --input-file ./data/parties.txt \
    --output-file ./data/paint_contract.txt

daml script --dar ./dars/SecureDaml.dar \
    --script-name Workflow:acceptOffer \
    --ledger-host $PARTICIPANT_1_HOST --ledger-port $PARTICIPANT_1_PORT \
    --access-token-file=${ROOTDIR}/certs/participant1/jwt/alice.token \
    --application-id "alice" \
    --tls --pem ${ROOTDIR}/certs/participant1/client/admin-api.customer1.com.key.pem \
    --crt ${ROOTDIR}/certs/participant1/client/admin-api.customer1.com.cert.pem \
    --cacrt "${ROOTDIR}/certs/participant1/intermediate/certs/ca-chain.cert.pem" \
    --input-file ./data/parties.txt \
    --output-file ./data/accept_contract.txt

daml script --dar ./dars/SecureDaml.dar \
    --script-name Workflow:callOffer \
    --ledger-host $PARTICIPANT_2_HOST --ledger-port $PARTICIPANT_2_PORT \
    --access-token-file=${ROOTDIR}/certs/participant2/jwt/bob.token \
    --application-id "bob" \
    --tls --pem ${ROOTDIR}/certs/participant2/client/admin-api.customer2.com.key.pem \
    --crt ${ROOTDIR}/certs/participant2/client/admin-api.customer2.com.cert.pem \
    --cacrt "${ROOTDIR}/certs/participant2/intermediate/certs/ca-chain.cert.pem" \
    --input-file ./data/parties.txt \
    --output-file ./data/cash_contract.txt

daml script --dar ./dars/SecureDaml.dar \
    --script-name Workflow:archiveCash \
    --ledger-host $PARTICIPANT_2_HOST --ledger-port $PARTICIPANT_2_PORT \
    --access-token-file=${ROOTDIR}/certs/participant2/jwt/navigator.token \
    --application-id "navigator" \
    --tls --pem ${ROOTDIR}/certs/participant2/client/admin-api.customer2.com.key.pem \
    --crt ${ROOTDIR}/certs/participant2/client/admin-api.customer2.com.cert.pem \
    --cacrt "${ROOTDIR}/certs/participant2/intermediate/certs/ca-chain.cert.pem" \
    --input-file ./data/parties.txt \
    --output-file ./data/archive_contract.txt

}

get-participants participant1 $PARTICIPANT_1_HOST $PARTICIPANT_1_PORT customer1.com
setup-participant participant1 $PARTICIPANT_1_HOST $PARTICIPANT_1_PORT customer1.com
setup-participant participant2 $PARTICIPANT_2_HOST $PARTICIPANT_2_PORT customer2.com

# Need to cpombine the two outputs from participant1 and participant2 to create a single file of Parties
# Display name is not copied across participants so cannot be used to lookup an identity
jq -s '.[0] * .[1]' ./data/script-output* > ./data/parties.txt

# Run through same CantonExamples workflow in Script
# Includes uploading DAR to each participant and then executing steps on each node.

# Rerun to create specific tokens tied to participants with correct "aud" field value
./make-jwt.sh

# Walk through example workflow
test_workflow





