#!/bin/bash
# Copyright (c) 2024 Digital Asset (Switzerland) GmbH and/or its affiliates. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

source env.sh

run_repl() {
  local namespace=$1
  local hostname=$2
  local port=$3
  local DOMAIN=$4
  local user=$5

  CLIENT_CERT_AUTH=TRUE
  CLIENT_CERT_PARAM=""
  if [ "$CLIENT_CERT_AUTH" == "TRUE" ] ; then
    echo "Enabling Client Certificate Auth"
    CLIENT_CERT_PARAM="--pem ${ROOTDIR}/certs/$namespace/client/admin-api.$DOMAIN.key.pem --crt ${ROOTDIR}/certs/$namespace/client/admin-api.$DOMAIN.cert.pem "
  fi

  AUTH_TOKEN=`cat "${ROOTDIR}/certs/$namespace/jwt/$user.token"`
  ./decode-jwt.sh "${ROOTDIR}/certs/$namespace/jwt/$user.token"

  daml repl ./dars/SecureDaml.dar \
    --import ex-secure-canton-infra-0.0.1 \
    --ledger-host $hostname --ledger-port $port \
    --access-token-file=${ROOTDIR}/certs/$namespace/jwt/$user.token \
    --application-id "$user" \
    --tls $CLIENT_CERT_PARAM \
    --cacrt "${ROOTDIR}/certs/$namespace/intermediate/certs/ca-chain.cert.pem" 

}

if [ $1 == "p1" ] ; then
  run_repl participant1 $PARTICIPANT_1_HOST $PARTICIPANT_1_PORT customer1.com participant_admin
fi

if [ $1 == "p2" ] ; then
  run_repl participant2 $PARTICIPANT_2_HOST $PARTICIPANT_2_PORT customer2.com participant_admin
fi

if [ $1 == "bank" ] ; then
  run_repl participant2 $PARTICIPANT_2_HOST $PARTICIPANT_2_PORT customer2.com bank
fi

if [ $1 == "bob" ] ; then
  run_repl participant2 $PARTICIPANT_2_HOST $PARTICIPANT_2_PORT customer2.com bob
fi

if [ $1 == "alice" ] ; then
  run_repl participant1 $PARTICIPANT_1_HOST $PARTICIPANT_1_PORT customer1.com alice
fi

if [ $1 == "p2-navigator" ] ; then
  run_repl participant2 $PARTICIPANT_2_HOST $PARTICIPANT_2_PORT customer2.com navigator
fi

