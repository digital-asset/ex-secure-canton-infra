#!/bin/bash
# Copyright (c) 2024 Digital Asset (Switzerland) GmbH and/or its affiliates. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

# set -e

source env.sh

ENABLE_HA="LOADBALANCER"

if [ ! "LOADBALANCER" == "$ENABLE_HA" ] ; then
   echo " Not running as not in Load Balancer mode"
   exit 1
fi

# Run NGINX load balancer for Participant

case "$(uname -s)" in
  Darwin)
    #JSON_API_2_HOST=host.docker.internal
    JSON_API_2A_HOST=host.docker.internal
    JSON_API_2B_HOST=host.docker.internal
    ;;
esac

# https://fardog.io/blog/2017/12/30/client-side-certificate-authentication-with-nginx/

docker stop lb-json-p2
docker rm lb-json-p2

DOMAIN=customer2.com

if [ "NGINX" == "$LOADBALANCER_TYPE" ] ; then

cat ./nginx-conf/nginx.conf-json-template | \
  sed -e "s;<DOMAIN>;$DOMAIN;g" | \
  sed -e "s;<JSON_API_HOST>;$JSON_API_2_HOST;g" | \
  sed -e "s;<JSON_API_PORT>;$JSON_API_2_PORT;g" | \
  sed -e "s;<JSON_API_A_HOST>;$JSON_API_2A_HOST;g" | \
  sed -e "s;<JSON_API_A_PORT>;$JSON_API_2A_PORT;g" \
   > ./nginx-conf/nginx-json-p2.conf

docker run --name lb-json-p2 -p $JSON_API_2_PORT:$JSON_API_2_PORT  \
  -v "$(pwd)/nginx-conf/nginx-json-p2.conf:/etc/nginx/nginx.conf:ro" \
  -v "$(pwd)/certs/participant2/json/certs/json-chain.$DOMAIN.cert.pem:/etc/ssl/server.crt:ro" \
  -v "$(pwd)/certs/participant2/json/private/json.$DOMAIN.key.pem:/etc/ssl/server.key:ro" \
  -v "$(pwd)/certs/participant2/intermediate/certs/ca-chain.cert.pem:/etc/ssl/certs/ca-chain.crt:ro" \
  -v "$(pwd)/certs/participant2/client/admin-api.$DOMAIN.cert.pem:/etc/ssl/client.crt:ro" \
  -v "$(pwd)/certs/participant2/client/admin-api.$DOMAIN.key.pem:/etc/ssl/client.key:ro" \
  -d $LOADBALANCER_VERSION

fi

if [ "HAPROXY" == "$LOADBALANCER_TYPE" ] ; then

cat ./haproxy-conf/haproxy.conf-json-template | \
  sed -e "s;<DOMAIN>;$DOMAIN;g" | \
  sed -e "s;<JSON_API_HOST>;$JSON_API_2_HOST;g" | \
  sed -e "s;<JSON_API_PORT>;$JSON_API_2_PORT;g" | \
  sed -e "s;<JSON_API_A_HOST>;$JSON_API_2A_HOST;g" | \
  sed -e "s;<JSON_API_A_PORT>;$JSON_API_2A_PORT;g" \
   > ./haproxy-conf/haproxy-json-p2.conf

docker run --name lb-json-p2 -p $JSON_API_2_PORT:$JSON_API_2_PORT  \
  --sysctl net.ipv4.ip_unprivileged_port_start=0 \
  -v "$(pwd)/haproxy-conf/haproxy-json-p2.conf:/usr/local/etc/haproxy/haproxy.cfg:ro" \
  -v "$(pwd)/certs/participant2/json/certs/json-chain.$DOMAIN.cert.pem:/etc/ssl/server.crt:ro" \
  -v "$(pwd)/certs/participant2/json/private/json.$DOMAIN.key.pem:/etc/ssl/server.crt.key:ro" \
  -v "$(pwd)/certs/participant2/intermediate/certs/ca-chain.cert.pem:/etc/ssl/certs/ca-chain.crt:ro" \
  -v "$(pwd)/certs/participant2/client/admin-api.$DOMAIN.cert.pem:/etc/ssl/client.crt:ro" \
  -v "$(pwd)/certs/participant2/client/admin-api.$DOMAIN.key.pem:/etc/ssl/client.crt.key:ro" \
  -P -d $LOADBALANCER_VERSION

fi
