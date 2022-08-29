#!/bin/bash
# Copyright (c) 2022 Digital Asset (Switzerland) GmbH and/or its affiliates. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

ROOTDIR=$PWD

# set the environment variable CANTON_DIR to the root of the canton directory tree.  used to find the canon command
if [[ -z ${CANTON_DIR} ]];then
    CANTON_DIR=./canton-enterprise-2.3.2
fi
echo "Canton directory is:  ${CANTON_DIR}"	

echo "Checking for required executables"

command -v openssl >/dev/null 2>&1 || { echo >&2 "I require openssl but it's not installed.  Aborting."; exit 1; }
OPENSSL_VERSION=`openssl version | grep -i openssl`
if [ "" == "$OPENSSL_VERSION" ] ; then
    echo "Please ensure Open-Source OpenSSL is installed and in path. For MacOS, Apple version is missing some features"
    exit 1
fi

command -v jq >/dev/null 2>&1 || { echo >&2 "I require jq but it's not installed.  Aborting."; exit 1; }
command -v grpcurl >/dev/null 2>&1 || { echo >&2 "I require grpcurl but it's not installed.  Aborting."; exit 1; }

if [ ! -f "$CANTON_DIR/bin/canton" ] ; then
    echo "Canton executable not found!. Aborting"
    exit 1
fi

# Switch the comment on the following two lines to enable or disable daemon mode for services
# Console is occasionally requires for certain operations (key management) directly on node and not remote console.
export RUN_AS_DAEMON=""
# export RUN_AS_DAEMON=" daemon "

# Following options relate to HA

# HA can be "CLIENTSIDE" or "LOADBALANCER" or "NONE".  Default is no load balancing since it doesn't require another
# binary for the load balancer.  In most cases "NONE" will reuse values from "CLIENTSIDE".
#export ENABLE_HA="CLIENTSIDE"
#export ENABLE_HA="LOADBALANCER"
export ENABLE_HA="NONE"
echo "Load Balancer Mode: $ENABLE_HA"

if [ "LOADBALANCER" == "$ENABLE_HA" ] ; then
# Select the loadbalancer
#LOADBALANCER_TYPE="NGINX"
LOADBALANCER_TYPE="HAPROXY"
echo "Using Load Balancer of type: $LOADBALANCER_TYPE"
fi

source env-ports.sh

# export _JAVA_OPTIONS="-Djava.net.preferIPv4Stack=true"

# Find local IP of machine so it can be added to certificate CN
case "$(uname -s)" in
	Darwin)
		LOCAL_IP=`ifconfig | grep "inet " | grep -Fv 127.0.0.1 |  grep -Fv 169.254 | head -n 1 | awk '{print $2}'`
		;;
	Linux)
		LOCAL_IP=`hostname -I | sed 's/ $//g' | head -n 1 | sed 's/ /,IP:/g'`
		;;
esac
