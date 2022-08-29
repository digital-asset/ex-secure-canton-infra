#!/bin/bash
# Copyright (c) 2020 Digital Asset (Switzerland) GmbH and/or its affiliates. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

# set -e

source env.sh

if [ ! "LOADBALANCER" == "$ENABLE_HA" ] ; then
   echo " Not running as not in Load Balancer mode"
   exit 1
fi

# Run NGINX load balancer for Sequencer

# https://fardog.io/blog/2017/12/30/client-side-certificate-authentication-with-nginx/

case "$(uname -s)" in
  Darwin)
    SEQUENCER_1_HOST=host.docker.internal
    SEQUENCER_2_HOST=host.docker.internal
    ;;
esac

docker stop lb-sequencer
docker rm lb-sequencer

DOMAIN=acme.com

if [ "NGINX" == "$LOADBALANCER_TYPE" ] ; then

cat ./nginx-conf/nginx.conf-sequencer-template | \
  sed -e "s;<DOMAIN>;$DOMAIN;g" | \
  sed -e "s;<SEQUENCER_1_HOST>;$SEQUENCER_1_HOST;g" | \
  sed -e "s;<CANTON_SEQUENCER_1_PUBLIC_PORT>;$CANTON_SEQUENCER_1_PUBLIC_PORT;g" | \
  sed -e "s;<SEQUENCER_2_HOST>;$SEQUENCER_2_HOST;g" | \
  sed -e "s;<CANTON_SEQUENCER_2_PUBLIC_PORT>;$CANTON_SEQUENCER_2_PUBLIC_PORT;g" | \
  sed -e "s;<SEQUENCER_HOST>;$SEQUENCER_HOST;g" | \
  sed -e "s;<SEQUENCER_PORT>;$SEQUENCER_PORT;g" \
   > ./nginx-conf/nginx-sequencer.conf

docker run --name lb-sequencer -p $SEQUENCER_PORT:$SEQUENCER_PORT  \
  -v "$(pwd)/nginx-conf/nginx-sequencer.conf:/etc/nginx/nginx.conf:ro" \
  -v "$(pwd)/certs/domain/sequencer/certs/sequencer-chain.$DOMAIN.cert.pem:/etc/ssl/server.crt:ro" \
  -v "$(pwd)/certs/domain/sequencer/private/sequencer.$DOMAIN.key.pem:/etc/ssl/server.key:ro" \
  -v "$(pwd)/certs/domain/intermediate/certs/ca-chain.cert.pem:/etc/ssl/certs/ca-chain.crt:ro" \
  -v "$(pwd)/certs/domain/client/admin-api.$DOMAIN.cert.pem:/etc/ssl/client.crt:ro" \
  -v "$(pwd)/certs/domain/client/admin-api.$DOMAIN.key.pem:/etc/ssl/client.key:ro" \
  -P -d nginx:1.23.1

fi

if [ "HAPROXY" == "$LOADBALANCER_TYPE" ] ; then

cat ./haproxy-conf/haproxy.conf-sequencer-template | \
  sed -e "s;<DOMAIN>;$DOMAIN;g" | \
  sed -e "s;<SEQUENCER_1_HOST>;$SEQUENCER_1_HOST;g" | \
  sed -e "s;<CANTON_SEQUENCER_1_PUBLIC_PORT>;$CANTON_SEQUENCER_1_PUBLIC_PORT;g" | \
  sed -e "s;<SEQUENCER_2_HOST>;$SEQUENCER_2_HOST;g" | \
  sed -e "s;<CANTON_SEQUENCER_2_PUBLIC_PORT>;$CANTON_SEQUENCER_2_PUBLIC_PORT;g" | \
  sed -e "s;<SEQUENCER_HOST>;$SEQUENCER_HOST;g" | \
  sed -e "s;<SEQUENCER_PORT>;$SEQUENCER_PORT;g" \
   > ./haproxy-conf/haproxy-sequencer.conf

docker run --name lb-sequencer -p $SEQUENCER_PORT:$SEQUENCER_PORT  \
  --sysctl net.ipv4.ip_unprivileged_port_start=0 \
  -v "$(pwd)/haproxy-conf/haproxy-sequencer.conf:/usr/local/etc/haproxy/haproxy.cfg:ro" \
  -v "$(pwd)/certs/domain/sequencer/certs/sequencer-chain.$DOMAIN.cert.pem:/etc/ssl/server.crt:ro" \
  -v "$(pwd)/certs/domain/sequencer/private/sequencer.$DOMAIN.key.pem:/etc/ssl/server.crt.key:ro" \
  -v "$(pwd)/certs/domain/intermediate/certs/ca-chain.cert.pem:/etc/ssl/certs/ca-chain.crt:ro" \
  -v "$(pwd)/certs/domain/client/admin-api.$DOMAIN.cert.pem:/etc/ssl/client.crt:ro" \
  -v "$(pwd)/certs/domain/client/admin-api.$DOMAIN.key.pem:/etc/ssl/client.crt.key:ro" \
  -P -d haproxy:2.6.2-alpine

fi
