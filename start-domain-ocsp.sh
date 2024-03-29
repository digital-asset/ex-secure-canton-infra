#!/bin/bash
# Copyright (c) 2024 Digital Asset (Switzerland) GmbH and/or its affiliates. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

#set -euo pipefail

# https://jamielinux.com/docs/openssl-certificate-authority/online-certificate-status-protocol.html
# https://www.shellhacks.com/create-csr-openssl-without-prompt-non-interactive/
# https://akshayranganath.github.io/OCSP-Validation-With-Openssl/
# https://medium.com/@KentaKodashima/generate-pem-keys-with-openssl-on-macos-ecac55791373

# OpenSSL testing of certs: https://www.feistyduck.com/library/openssl-cookbook/online/ch-testing-with-openssl.html

create_CRL() {
  # Create CRL for certificate

  openssl ca -config $ROOTDIR/certs/domain/intermediate/openssl.cnf \
      -gencrl -out $ROOTDIR/certs/domain/intermediate/crl/intermediate.crl.pem

  # Check CRL
  openssl crl -in $ROOTDIR/certs/domain/intermediate/crl/intermediate.crl.pem -noout -text
}

create_ocsp_key() {
  echo "Creating OCSP Server Key"

  # Create OCSP 
  openssl genrsa \
      -out $ROOTDIR/certs/domain/intermediate/private/ocsp.$DOMAIN.key.pem 4096

  openssl req -config $ROOTDIR/certs/domain/intermediate/openssl.cnf -new -sha256 \
      -subj "/C=US/ST=New York/O=$DOMAIN_NAME/CN=ocsp.$DOMAIN" \
      -key $ROOTDIR/certs/domain/intermediate/private/ocsp.$DOMAIN.key.pem \
      -out $ROOTDIR/certs/domain/intermediate/csr/ocsp.$DOMAIN.csr.pem

  openssl ca -batch -config $ROOTDIR/certs/domain/intermediate/openssl.cnf \
      -extensions ocsp -days 375 -notext -md sha256 \
      -in $ROOTDIR/certs/domain/intermediate/csr/ocsp.$DOMAIN.csr.pem \
      -out $ROOTDIR/certs/domain/intermediate/certs/ocsp.$DOMAIN.cert.pem

  # Validate extensions
  openssl x509 -noout -text \
      -in $ROOTDIR/certs/domain/intermediate/certs/ocsp.$DOMAIN.cert.pem
}

create_test() {
  echo "Creating Test certificate"

  openssl genrsa -out $ROOTDIR/certs/domain/server/private/test.$DOMAIN.key.pem 2048
  openssl req -config $ROOTDIR/certs/domain/intermediate/openssl.cnf \
      -subj "/C=US/ST=New York/O=DOMAIN_NAME/CN=test.$DOMAIN" \
      -key $ROOTDIR/certs/domain/server/private/test.$DOMAIN.key.pem \
      -new -sha256 -out $ROOTDIR/certs/domain/server/csr/test.$DOMAIN.csr.pem
  openssl ca -batch -config $ROOTDIR/certs/domain/intermediate/openssl.cnf \
      -extensions server_cert -days 375 -notext -md sha256 \
      -in $ROOTDIR/certs/domain/server/csr/test.$DOMAIN.csr.pem \
      -out $ROOTDIR/certs/domain/server/certs/test.$DOMAIN.cert.pem

  openssl x509 -noout -ocsp_uri -in "$ROOTDIR/certs/domain/server/certs/test.$DOMAIN.cert.pem"
}

start_ocsp() {
  echo "Starting OCSP responder"

  cd $ROOTDIR 

  # Note that this is set to only listen for one request and then terminate
  openssl ocsp -port $OCSP_DOMAIN_INTERMEDIATE_PORT -text \
    -index "$(pwd)/certs/domain/intermediate/index.txt" \
    -CA "$(pwd)/certs/domain/intermediate/certs/ca-chain.cert.pem" \
    -rkey "$(pwd)/certs/domain/intermediate/private/ocsp.$DOMAIN.key.pem" \
    -rsigner "$(pwd)/certs/domain/intermediate/certs/ocsp.$DOMAIN.cert.pem" \
    -nrequest 1 &

  sleep 3
}

start_ocsp_longrunning() {
  echo "Starting OCSP responder"

  cd $ROOTDIR 

  # Note that this is set to only listen for one request and then terminate
  x=1
  while [ $x -le 20 ]
  do
    if [ -f ocsp_kill_switch ] ; then
       exit 0
    fi
    openssl ocsp -port $OCSP_DOMAIN_INTERMEDIATE_PORT -text \
      -index "$(pwd)/certs/domain/intermediate/index.txt" \
      -CA "$(pwd)/certs/domain/intermediate/certs/ca-chain.cert.pem" \
      -rkey "$(pwd)/certs/domain/intermediate/private/ocsp.$DOMAIN.key.pem" \
      -rsigner "$(pwd)/certs/domain/intermediate/certs/ocsp.$DOMAIN.cert.pem" \
      -multi 1 \
      -timeout 5

    x=$(( $x + 1 ))
  done

}

check_ocsp_response() {
  echo "Check OCSP response"
  openssl ocsp -CAfile "$ROOTDIR/certs/domain/intermediate/certs/ca-chain.cert.pem" \
      -url http://127.0.0.1:$OCSP_DOMAIN_INTERMEDIATE_PORT -resp_text \
      -issuer "$ROOTDIR/certs/domain/intermediate/certs/intermediate.cert.pem" \
      -cert "$ROOTDIR/certs/domain/server/certs/test.$DOMAIN.cert.pem"
}

revoke_test() {
  echo "Revoking certificate"
  openssl ca -batch -config "$ROOTDIR/certs/domain/intermediate/openssl.cnf" \
      -revoke "$ROOTDIR/certs/domain/server/certs/test.$DOMAIN.cert.pem"
}

source env.sh

DOMAIN="acme.com"
DOMAIN_NAME="ACME Corp LLC"

export ROOTDIR=$PWD
cd $ROOTDIR

if [ ! -d certs ] ; then
 echo "ERROR: You need to create PKI CA hierarchy first!"
 exit
fi

if [ ! -d $ROOTDIR/certs/domain/server ] ; then
   mkdir $ROOTDIR/certs/domain/server
   mkdir $ROOTDIR/certs/domain/server/certs
   mkdir $ROOTDIR/certs/domain/server/private
   mkdir $ROOTDIR/certs/domain/server/csr
fi

if [ ! -f $ROOTDIR/certs/domain/intermediate/private/ocsp.$DOMAIN.key.pem ]; then
   create_ocsp_key
fi

create_test
start_ocsp
check_ocsp_response
revoke_test
start_ocsp
check_ocsp_response

start_ocsp_longrunning



