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

#LOADBALANCER_TYPE="NGINX"
LOADBALANCER_TYPE="HAPROXY"

# Run NGINX load balancer for Participant

case "$(uname -s)" in
  Darwin)
    #JSON_API_1_HOST=host.docker.internal
    JSON_API_1A_HOST=host.docker.internal
    JSON_API_1B_HOST=host.docker.internal
    ;;
esac

# https://fardog.io/blog/2017/12/30/client-side-certificate-authentication-with-nginx/

docker stop lb-json-p1
docker rm lb-json-p1

DOMAIN=customer1.com

if [ "NGINX" == "$LOADBALANCER_TYPE" ] ; then

cat ./nginx-conf/nginx.conf-json-template | \
  sed -e "s;<DOMAIN>;$DOMAIN;g" | \
  sed -e "s;<JSON_API_HOST>;$JSON_API_1_HOST;g" | \
  sed -e "s;<JSON_API_PORT>;$JSON_API_1_PORT;g" | \
  sed -e "s;<JSON_API_A_HOST>;$JSON_API_1A_HOST;g" | \
  sed -e "s;<JSON_API_A_PORT>;$JSON_API_1A_PORT;g" | \
  sed -e "s;<JSON_API_B_HOST>;$JSON_API_1B_HOST;g" | \
  sed -e "s;<JSON_API_B_PORT>;$JSON_API_1B_PORT;g" \
   > ./nginx-conf/nginx-json-p1.conf

docker run --name lb-json-p1 -p $JSON_API_1_PORT:$JSON_API_1_PORT \
  -v "$(pwd)/nginx-conf/nginx-json-p1.conf:/etc/nginx/nginx.conf:ro" \
  -v "$(pwd)/certs/participant1/json/certs/json-chain.$DOMAIN.cert.pem:/etc/ssl/server.crt:ro" \
  -v "$(pwd)/certs/participant1/json/private/json.$DOMAIN.key.pem:/etc/ssl/server.key:ro" \
  -v "$(pwd)/certs/participant1/intermediate/certs/ca-chain.cert.pem:/etc/ssl/certs/ca-chain.crt:ro" \
  -v "$(pwd)/certs/participant1/client/admin-api.$DOMAIN.cert.pem:/etc/ssl/client.crt:ro" \
  -v "$(pwd)/certs/participant1/client/admin-api.$DOMAIN.key.pem:/etc/ssl/client.key:ro" \
  -d nginx:1.23.1-alpine

fi

if [ "HAPROXY" == "$LOADBALANCER_TYPE" ] ; then

cat ./haproxy-conf/haproxy.conf-json-template | \
  sed -e "s;<DOMAIN>;$DOMAIN;g" | \
  sed -e "s;<JSON_API_HOST>;$JSON_API_1_HOST;g" | \
  sed -e "s;<JSON_API_PORT>;$JSON_API_1_PORT;g" | \
  sed -e "s;<JSON_API_A_HOST>;$JSON_API_1A_HOST;g" | \
  sed -e "s;<JSON_API_A_PORT>;$JSON_API_1A_PORT;g" | \
  sed -e "s;<JSON_API_B_HOST>;$JSON_API_1B_HOST;g" | \
  sed -e "s;<JSON_API_B_PORT>;$JSON_API_1B_PORT;g" \
   > ./haproxy-conf/haproxy-json-p1.conf

docker run --name lb-json-p1 -p $JSON_API_1_PORT:$JSON_API_1_PORT  \
  --sysctl net.ipv4.ip_unprivileged_port_start=0 \
  -v "$(pwd)/haproxy-conf/haproxy-json-p1.conf:/usr/local/etc/haproxy/haproxy.cfg:ro" \
  -v "$(pwd)/certs/participant1/json/certs/json-chain.$DOMAIN.cert.pem:/etc/ssl/server.crt:ro" \
  -v "$(pwd)/certs/participant1/json/private/json.$DOMAIN.key.pem:/etc/ssl/server.crt.key:ro" \
  -v "$(pwd)/certs/participant1/intermediate/certs/ca-chain.cert.pem:/etc/ssl/certs/ca-chain.crt:ro" \
  -v "$(pwd)/certs/participant1/client/admin-api.$DOMAIN.cert.pem:/etc/ssl/client.crt:ro" \
  -v "$(pwd)/certs/participant1/client/admin-api.$DOMAIN.key.pem:/etc/ssl/client.crt.key:ro" \
  -P -d haproxy:2.6.2-alpine

fi
