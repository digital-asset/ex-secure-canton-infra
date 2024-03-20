#!/bin/bash
# Copyright (c) 2024 Digital Asset (Switzerland) GmbH and/or its affiliates. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

# set -e

source env.sh

if [ ! "LOADBALANCER" == "$ENABLE_HA" ] ; then
   echo " Not running as not in Load Balancer mode"
   exit 1
fi

# Run NGINX load balancer for Participant

case "$(uname -s)" in
  Darwin)
    PARTICIPANT_1_HOST=host.docker.internal
    PARTICIPANT_1B_HOST=host.docker.internal
    ;;
esac

# https://fardog.io/blog/2017/12/30/client-side-certificate-authentication-with-nginx/

docker stop lb-participant1
docker rm lb-participant1

DOMAIN=customer1.com

if [ "NGINX" == "$LOADBALANCER_TYPE" ] ; then

cat ./nginx-conf/nginx.conf-participant1-template | \
  sed -e "s;<DOMAIN>;$DOMAIN;g" | \
  sed -e "s;<PARTICIPANT_1_HOST>;$PARTICIPANT_1_HOST;g" | \
  sed -e "s;<PARTICIPANT_1_PORT>;$PARTICIPANT_1_PORT;g" | \
  sed -e "s;<CANTON_PARTICIPANT_1_LEDGER_PORT>;$CANTON_PARTICIPANT_1_LEDGER_PORT;g" | \
  sed -e "s;<PARTICIPANT_1B_HOST>;$PARTICIPANT_1B_HOST;g" | \
  sed -e "s;<CANTON_PARTICIPANT_1B_LEDGER_PORT>;$CANTON_PARTICIPANT_1B_LEDGER_PORT;g" \
   > ./nginx-conf/nginx-participant1.conf

docker run --name lb-participant1 -p $PARTICIPANT_1_PORT:$PARTICIPANT_1_PORT  \
  -v "$(pwd)/nginx-conf/nginx-participant1.conf:/etc/nginx/nginx.conf:ro" \
  -v "$(pwd)/certs/participant1/participant1/certs/participant1-chain.$DOMAIN.cert.pem:/etc/ssl/server.crt:ro" \
  -v "$(pwd)/certs/participant1/participant1/private/participant1.$DOMAIN.key.pem:/etc/ssl/server.key:ro" \
  -v "$(pwd)/certs/participant1/intermediate/certs/ca-chain.cert.pem:/etc/ssl/certs/ca-chain.crt:ro" \
  -v "$(pwd)/certs/participant1/client/admin-api.$DOMAIN.cert.pem:/etc/ssl/client.crt:ro" \
  -v "$(pwd)/certs/participant1/client/admin-api.$DOMAIN.key.pem:/etc/ssl/client.key:ro" \
  -P -d $LOADBALANCER_VERSION

fi

if [ "HAPROXY" == "$LOADBALANCER_TYPE" ] ; then

cat ./haproxy-conf/haproxy.conf-participant1-template | \
  sed -e "s;<DOMAIN>;$DOMAIN;g" | \
  sed -e "s;<HEALTHCHECK_1_PORT>;$HEALTHCHECK_1_PORT;g" | \
  sed -e "s;<HEALTHCHECK_1B_PORT>;$HEALTHCHECK_1B_PORT;g" | \
  sed -e "s;<PARTICIPANT_1_HOST>;$PARTICIPANT_1_HOST;g" | \
  sed -e "s;<PARTICIPANT_1_PORT>;$PARTICIPANT_1_PORT;g" | \
  sed -e "s;<CANTON_PARTICIPANT_1_LEDGER_PORT>;$CANTON_PARTICIPANT_1_LEDGER_PORT;g" | \
  sed -e "s;<PARTICIPANT_1B_HOST>;$PARTICIPANT_1B_HOST;g" | \
  sed -e "s;<CANTON_PARTICIPANT_1B_LEDGER_PORT>;$CANTON_PARTICIPANT_1B_LEDGER_PORT;g" \
   > ./haproxy-conf/haproxy-participant1.conf

docker run --name lb-participant1 -p $PARTICIPANT_1_PORT:$PARTICIPANT_1_PORT  \
  --sysctl net.ipv4.ip_unprivileged_port_start=0 \
  -v "$(pwd)/haproxy-conf/haproxy-participant1.conf:/usr/local/etc/haproxy/haproxy.cfg:ro" \
  -v "$(pwd)/certs/participant1/participant1/certs/participant1-chain.$DOMAIN.cert.pem:/etc/ssl/server.crt:ro" \
  -v "$(pwd)/certs/participant1/participant1/private/participant1.$DOMAIN.key.pem:/etc/ssl/server.crt.key:ro" \
  -v "$(pwd)/certs/participant1/intermediate/certs/ca-chain.cert.pem:/etc/ssl/certs/ca-chain.crt:ro" \
  -v "$(pwd)/certs/participant1/client/admin-api.$DOMAIN.cert.pem:/etc/ssl/client.crt:ro" \
  -v "$(pwd)/certs/participant1/client/admin-api.$DOMAIN.key.pem:/etc/ssl/client.crt.key:ro" \
  -P -d $LOADBALANCER_VERSION

fi
