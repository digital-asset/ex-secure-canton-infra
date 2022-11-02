#!/bin/bash
# Copyright (c) 2022 Digital Asset (Switzerland) GmbH and/or its affiliates. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

# https://www.jvt.me/posts/2019/06/13/pretty-printing-jwt-openssl/
source env.sh

function jwt() {
  for part in 1 2; do
    b64="$(cut -f$part -d. <<< "$1" | tr '_-' '/+' | tr -d ' ' )"
    len=${#b64}
    n=$((len % 4))
    if [[ 2 -eq n ]]; then
      b64="${b64}=="
    elif [[ 3 -eq n ]]; then
      b64="${b64}="
    fi
    d="$(openssl enc -base64 -d -A <<< "$b64")"
    python3 -mjson.tool <<< "$d"
    # don't decode further if this is an encrypted JWT (JWE)
    if [[ 1 -eq part ]] && grep '"enc":' <<< "$d" >/dev/null ; then
        exit 0
    fi
    if [[ 2 -eq part ]] ; then
       PAYLOAD="$d"
    fi
  done
}

if [ ! -f $1 ] ; then
   echo "ERROR: Invalid filename provided!!"
   exit 1
fi

JWT=`cat $1`
jwt "$JWT"

EXPIRY_DATE=`echo $PAYLOAD | jq .exp`

get_os_type 
case ${_GET_OS_TYPE} in
  Darwin)
    EXPIRY_STR=`date -r "$EXPIRY_DATE" '+%m/%d/%Y:%H:%M:%S'`
    ;;
  Linux)
    EXPIRY_STR=`date -d "@$EXPIRY_DATE" '+%m/%d/%Y:%H:%M:%S'`
    ;;
  CYGWIN_NT)
    EXPIRY_STR=`date -d "@$EXPIRY_DATE" '+%m/%d/%Y:%H:%M:%S'`
    ;;
  *)
    echo "Unknown OS type of ${OS_TYPE}.   Aborting decode_jst.sh ..."
    exit 1
esac

echo "Expiry Date: $EXPIRY_STR"
