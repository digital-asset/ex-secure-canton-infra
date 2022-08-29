#!/bin/bash
# Copyright (c) 2020 Digital Asset (Switzerland) GmbH and/or its affiliates. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

# https://jamielinux.com/docs/openssl-certificate-authority/online-certificate-status-protocol.html
# https://www.shellhacks.com/create-csr-openssl-without-prompt-non-interactive/
# https://akshayranganath.github.io/OCSP-Validation-With-Openssl/
# https://medium.com/@KentaKodashima/generate-pem-keys-with-openssl-on-macos-ecac55791373

# OpenSSL testing of certs: https://www.feistyduck.com/library/openssl-cookbook/online/ch-testing-with-openssl.html

create_test_client() {
  echo "Creating Test Client certificate"

  openssl genpkey -out $ROOTDIR/certs/participant1/client/testclient.$DOMAIN.key.pem -algorithm RSA -pkeyopt rsa_keygen_bits:2048
  openssl req -config $ROOTDIR/certs/participant1/intermediate/openssl.cnf \
      -subj "/C=US/ST=New York/O=DOMAIN_NAME/CN=testclient.$DOMAIN" \
      -key $ROOTDIR/certs/participant1/client/testclient.$DOMAIN.key.pem \
      -new -sha256 -out $ROOTDIR/certs/participant1/client/testclient.$DOMAIN.csr.pem
  openssl ca -batch -config $ROOTDIR/certs/participant1/intermediate/openssl.cnf \
      -extensions usr_cert -days 375 -notext -md sha256 \
      -in $ROOTDIR/certs/participant1/client/testclient.$DOMAIN.csr.pem \
      -out $ROOTDIR/certs/participant1/client/testclient.$DOMAIN.cert.pem

  openssl x509 -noout -ocsp_uri -in "$ROOTDIR/certs/participant1/client/testclient.$DOMAIN.cert.pem"
}

check_ocsp_response() {
  echo "Check OCSP response"
  openssl ocsp -CAfile "$ROOTDIR/certs/participant1/intermediate/certs/ca-chain.cert.pem" \
      -url http://ocsp.$DOMAIN:$OCSP_PARTICIPANT1_INTERMEDIATE_PORT -resp_text \
      -issuer "$ROOTDIR/certs/participant1/intermediate/certs/intermediate.cert.pem" \
      -cert "$ROOTDIR/certs/participant1/client/testclient.$DOMAIN.cert.pem"
}

revoke_test() {
  echo "Revoking certificate"
  openssl ca -batch -config "$ROOTDIR/certs/participant1/intermediate/openssl.cnf" \
      -revoke "$ROOTDIR/certs/participant1/client/testclient.$DOMAIN.cert.pem" -crl_reason keyCompromise

  # CRL Reasons include:
  #  unspecified
  #  keyCompromise
  #  CACompromise
  #  affiliationChanged
  #  superseded
  #  cessationOfOperation
  #  certificateHold
  #  removeFromCRL

}

build_client_app() {

   cd $ROOTDIR/client-app
   sbt assembly
   cp target/scala-2.13/client.jar $JAR
}

run_client_app() {

   cd $ROOTDIR/client-app
   java -Djava.security.properties=$ROOTDIR/java.security -Dcom.sun.net.ssl.checkRevocation=true -Djava.security.debug="certpath ocsp" -Djdk.tls.client.enableStatusRequestExtension=true -jar $JAR localhost 10011 $CLIENT_CERT $CLIENT_KEY $CA_CERT $AUTH_TOKEN

}

# On MacOS use brew installed openssl 1.1.1
export PATH=/usr/local/opt/openssl/bin:$PATH

source env.sh

DOMAIN="customer1.com"
DOMAIN_NAME="Customer1 LLC"

export ROOTDIR=$PWD
cd $ROOTDIR

CERTS_DIR="$ROOTDIR/certs/participant1"
JAR="$ROOTDIR/client-app/client.jar"
CLIENT_CERT="$CERTS_DIR/client/testclient.$DOMAIN.cert.pem"
CLIENT_KEY="$CERTS_DIR/client/testclient.$DOMAIN.key.pem"
CA_CERT="$CERTS_DIR/intermediate/certs/ca-chain.cert.pem"

if [ ! -d "$CERTS_DIR" ] ; then
 echo "ERROR: You need to create PKI CA hierarchy first!"
 exit
fi

if [ ! -f "$JAR" ] ; then
  build_client_app
fi

AUTH_TOKEN=`cat "$ROOTDIR/certs/participant1/jwt/participant_admin.token"`
#echo $AUTH_TOKEN

create_test_client
sleep 2
check_ocsp_response
check_ocsp_response
run_client_app

revoke_test
sleep 2
check_ocsp_response
check_ocsp_response
run_client_app

rm $JAR
