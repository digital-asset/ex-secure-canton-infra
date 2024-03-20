#!/bin/bash
# Copyright (c) 2024 Digital Asset (Switzerland) GmbH and/or its affiliates. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

set -e

# https://jamielinux.com/docs/openssl-certificate-authority/online-certificate-status-protocol.html
# https://www.shellhacks.com/create-csr-openssl-without-prompt-non-interactive/
# https://akshayranganath.github.io/OCSP-Validation-With-Openssl/
# https://medium.com/@KentaKodashima/generate-pem-keys-with-openssl-on-macos-ecac55791373

# OpenSSL testing of certs: https://www.feistyduck.com/library/openssl-cookbook/online/ch-testing-with-openssl.html

# NOTE:  proting to Cygwin required chaging absolute file paths to relative file paths.  Cygwin has a wart.

clean_directory() {
  rm -rf certs
}

create_root() {
  local namespace=$1
  local DOMAIN=$2
  local DOMAIN_NAME=$3
  local OCSP_PORT=$4
  echo "Creating Root Key - $namespace"

  cd $ROOTDIR

  # Make Root Directory tree
  mkdir -p certs/$namespace/root
  cd $ROOTDIR/certs/$namespace/root

  mkdir certs crl newcerts private
  chmod 700 private
  touch index.txt
  echo 1000 > serial

  # go back to root dir to make the certs 
  cd $ROOTDIR 

  cat root-ca.cnf.sample | \
    sed -e "s;<namespace>;$namespace;g" \
    -e "s;<ROOTDIR>;.;g" \
    -e "s;<DOMAIN>;$DOMAIN;g" \
    -e "s;<OCSP_PORT>;$OCSP_PORT;g" \
    -e "s;<DOMAIN_NAME>;$DOMAIN_NAME;g" \
    > certs/$namespace/root/openssl.cnf

  # cat $ROOTDIR/root-ca.cnf.sample | \
  #   sed -e "s;<namespace>;$namespace;g" \
  #   -e "s;<ROOTDIR>;$ROOTDIR;g" \
  #   -e "s;<DOMAIN>;$DOMAIN;g" \
  #   -e "s;<OCSP_PORT>;$OCSP_PORT;g" \
  #   -e "s;<DOMAIN_NAME>;$DOMAIN_NAME;g" \
  #   > $ROOTDIR/certs/$namespace/root/openssl.cnf


  # Generate Root CA private key
  # echo "${OUT_DIR}/ca.key.pem"
  openssl genrsa -out certs/$namespace/root/private/ca.key.pem 4096
  chmod 400 certs/$namespace/root/private/ca.key.pem

  # Create Root Certificate (self-signed)
  openssl req -config certs/$namespace/root/openssl.cnf \
      -key certs/$namespace/root/private/ca.key.pem \
      -new -x509 -days 7300 -sha256 -extensions v3_ca \
      -subj "/C=US/ST=New York/O=$DOMAIN_NAME/CN=$namespace-root-ca.$DOMAIN" \
      -out certs/$namespace/root/certs/ca.cert.pem

  # openssl req -config $ROOTDIR/certs/$namespace/root/openssl.cnf \
  #     -key $ROOTDIR/certs/$namespace/root/private/ca.key.pem \
  #     -new -x509 -days 7300 -sha256 -extensions v3_ca \
  #     -subj "/C=US/ST=New York/O=$DOMAIN_NAME/CN=$namespace-root-ca.$DOMAIN" \
  #     -out $ROOTDIR/certs/$namespace/root/certs/ca.cert.pem

  # Dump out cert details
  openssl x509 -noout -text -in certs/$namespace/root/certs/ca.cert.pem
}

create_intermediate() {
  local namespace=$1
  local DOMAIN=$2
  local DOMAIN_NAME=$3
  local OCSP_PORT=$4
  echo "Creating Intermediate Key - $namespace"

  cd $ROOTDIR
  # Create Intermediate CA directory tree
  mkdir -p certs/$namespace/intermediate
  cd certs/$namespace/intermediate

  mkdir certs crl csr newcerts private
  chmod 700 private
  touch index.txt
  echo 1000 > serial
  echo 1000 > crlnumber

  # cat $ROOTDIR/intermediate-ca.cnf.sample | \
  #   sed -e "s;<namespace>;$namespace;g" \
  #   -e "s;<ROOTDIR>;$ROOTDIR;g" \
  #   -e "s;<DOMAIN>;$DOMAIN;g" \
  #   -e "s;<OCSP_PORT>;$OCSP_PORT;g" \
  #   -e "s;<DOMAIN_NAME>;$DOMAIN_NAME;g" \
  #   > $ROOTDIR/certs/$namespace/intermediate/openssl.cnf

  cd $ROOTDIR
  cat intermediate-ca.cnf.sample | \
    sed -e "s;<namespace>;$namespace;g" \
    -e "s;<ROOTDIR>;.;g" \
    -e "s;<DOMAIN>;$DOMAIN;g" \
    -e "s;<OCSP_PORT>;$OCSP_PORT;g" \
    -e "s;<DOMAIN_NAME>;$DOMAIN_NAME;g" \
    > certs/$namespace/intermediate/openssl.cnf

  # Generate Intermediate private key
  openssl genrsa -out certs/$namespace/intermediate/private/intermediate.key.pem 4096
  chmod 400 certs/$namespace/intermediate/private/intermediate.key.pem

  # Create Intermediate CSR request
  openssl req -config certs/$namespace/intermediate/openssl.cnf -new -sha256 \
      -subj "/C=US/ST=New York/O=$DOMAIN_NAME/CN=intermediate-ca.$DOMAIN" \
      -key certs/$namespace/intermediate/private/intermediate.key.pem \
      -out certs/$namespace/intermediate/csr/intermediate.csr.pem

  # Sign Intermediate Certificate by Root CA
  openssl ca -batch -config certs/$namespace/root/openssl.cnf -extensions v3_intermediate_ca \
      -days 3650 -notext -md sha256 \
      -in certs/$namespace/intermediate/csr/intermediate.csr.pem \
      -out certs/$namespace/intermediate/certs/intermediate.cert.pem
  chmod 444 certs/$namespace/intermediate/certs/intermediate.cert.pem

  # Verify Certificate
  openssl x509 -noout -text -in certs/$namespace/intermediate/certs/intermediate.cert.pem
}

create_certificatechain() {
  local namespace=$1

  cd $ROOTDIR

  # Create certificate chain
  cat certs/$namespace/intermediate/certs/intermediate.cert.pem \
      certs/$namespace/root/certs/ca.cert.pem > $ROOTDIR/certs/$namespace/intermediate/certs/ca-chain.cert.pem
  chmod 444 certs/$namespace/intermediate/certs/ca-chain.cert.pem
  cp certs/$namespace/root/certs/ca.cert.pem $ROOTDIR/certs/$namespace/intermediate/certs/root-ca.cert.pem
}

create_server_cert() {
  local namespace=$1
  local DOMAIN=$2
  local DOMAIN_NAME=$3
  local hostname=$4
  echo "Creating Server Key - $hostname $namespace"

  # Make server directory
  cd $ROOTDIR/certs/$namespace
  mkdir $hostname
  cd $hostname
  mkdir certs crl csr newcerts private
  chmod 700 private

  # Create Server Key
  cd $ROOTDIR

  # Need to create key in PKCS8 format not native RSA
  openssl genpkey -out certs/$namespace/$hostname/private/$hostname.$DOMAIN.key.pem -algorithm RSA -pkeyopt rsa_keygen_bits:2048
  chmod 400 certs/$namespace/$hostname/private/$hostname.$DOMAIN.key.pem

  # Create Server certificate
  openssl req -config certs/$namespace/intermediate/openssl.cnf \
      -subj "/C=US/ST=New York/O=$DOMAIN_NAME/CN=$hostname.$DOMAIN" \
      -addext "subjectAltName = DNS:$hostname.$DOMAIN,DNS:localhost,IP:127.0.0.1,IP:0.0.0.0,IP:$LOCAL_IP" \
      -key certs/$namespace/$hostname/private/$hostname.$DOMAIN.key.pem \
      -new -sha256 -out certs/$namespace/$hostname/csr/$hostname.$DOMAIN.csr.pem

  # Sign Certificate
  openssl ca -batch -config certs/$namespace/intermediate/openssl.cnf \
      -extensions server_cert -days 365 -notext -md sha256 \
      -in certs/$namespace/$hostname/csr/$hostname.$DOMAIN.csr.pem \
      -out certs/$namespace/$hostname/certs/$hostname.$DOMAIN.cert.pem
  chmod 444 certs/$namespace/$hostname/certs/$hostname.$DOMAIN.cert.pem

  openssl x509 -noout -text \
      -in certs/$namespace/$hostname/certs/$hostname.$DOMAIN.cert.pem

  # Validate chain of trust
  openssl verify -CAfile certs/$namespace/intermediate/certs/ca-chain.cert.pem \
      certs/$namespace/$hostname/certs/$hostname.$DOMAIN.cert.pem

  cat certs/$namespace/$hostname/certs/$hostname.$DOMAIN.cert.pem \
    certs/$namespace/intermediate/certs/ca-chain.cert.pem > certs/$namespace/$hostname/certs/$hostname-chain.$DOMAIN.cert.pem
}

verify_cert() {
  local namespace=$1
  local DOMAIN=$2
  local hostname=$3
  echo "Validate Server Cert"

  cd $ROOTDIR
  # Validate Server Certificate
  openssl x509 -in certs/$namespace/$hostname/certs/$hostname.$DOMAIN.cert.pem -noout -text
}

create_client() {
  local namespace=$1
  local DOMAIN=$2
  local DOMAIN_NAME=$3
  local clientname=$4
  echo "Creating Client Key"

  # Create a client certificate
  cd $ROOTDIR/certs/$namespace
  if [ ! -d client ]; then
    mkdir client
  fi
  # cd client

  cd $ROOTDIR

  openssl genpkey -out certs/$namespace/client/$clientname.$DOMAIN.key.pem -algorithm RSA -pkeyopt rsa_keygen_bits:2048
  openssl req -new -key certs/$namespace/client/$clientname.$DOMAIN.key.pem \
      -subj "/C=US/ST=New York/O=$DOMAIN_NAME/CN=$clientname" \
      -addext "subjectAltName = DNS:$clientname.$DOMAIN,DNS:localhost,IP:127.0.0.1,IP:0.0.0.0,IP:$LOCAL_IP" \
      -out certs/$namespace/client/$clientname.$DOMAIN.csr.pem

  # Sign Client Cert
  openssl ca -batch -config certs/$namespace/intermediate/openssl.cnf \
      -extensions usr_cert -notext -md sha256 \
      -in certs/$namespace/client/$clientname.$DOMAIN.csr.pem \
      -out certs/$namespace/client/$clientname.$DOMAIN.cert.pem

  # Validate cert is correct
  openssl verify -CAfile certs/$namespace/intermediate/certs/ca-chain.cert.pem \
      certs/$namespace/client/$clientname.$DOMAIN.cert.pem

  openssl x509 -in certs/$namespace/client/$clientname.$DOMAIN.cert.pem -inform pem -outform der \
    -out certs/$namespace/client/$clientname.$DOMAIN.cert.der
  openssl pkcs8 -topk8 -inform PEM -outform DER -in certs/$namespace/client/$clientname.$DOMAIN.key.pem \
    -out certs/$namespace/client/$clientname.$DOMAIN.key.der -nocrypt

}

revoke_client() {
  echo "Revoking client cert"

  # Revoke cert
  openssl ca -config $ROOTDIR/certs/intermediate/openssl.cnf \
      -revoke $ROOTDIR/certs/client/client1.$DOMAIN.cert.pem
}

# On MacOS use brew installed openssl 1.1.1
export PATH=/usr/local/opt/openssl/bin:$PATH

source env.sh

export ROOTDIR=$PWD
cd $ROOTDIR

if [ ! -d certs ] ; then
  mkdir certs
fi

clean_directory
create_root "domain" "acme.com" "ACME Corp LLC" $OCSP_DOMAIN_ROOT_PORT
create_intermediate "domain" "acme.com" "ACME Corp LLC" $OCSP_DOMAIN_INTERMEDIATE_PORT
create_certificatechain domain

create_root "participant1" "customer1.com" "Customer1 LLC" $OCSP_PARTICIPANT1_ROOT_PORT
create_intermediate "participant1" "customer1.com" "Customer1 LLC" $OCSP_PARTICIPANT1_INTERMEDIATE_PORT
create_certificatechain participant1

create_root "participant2" "customer2.com" "Customer2 LLC" $OCSP_PARTICIPANT2_ROOT_PORT
create_intermediate "participant2" "customer2.com" "Customer2 LLC" $OCSP_PARTICIPANT2_INTERMEDIATE_PORT
create_certificatechain participant2

create_server_cert "domain" "acme.com" "ACME Corp LLC" domain-manager
create_server_cert "domain" "acme.com" "ACME Corp LLC" sequencer
create_server_cert "domain" "acme.com" "ACME Corp LLC" mediator
create_server_cert "domain" "acme.com" "ACME Corp LLC" db
verify_cert "domain" "acme.com" domain-manager

create_client "domain" "acme.com" "ACME Corp LLC" admin-api
create_client "domain" "acme.com" "ACME Corp LLC" sequencer
create_client "domain" "acme.com" "ACME Corp LLC" mediator
create_client "domain" "acme.com" "ACME Corp LLC" domain
create_client "domain" "acme.com" "ACME Corp LLC" remote-admin

get_os_type 
if  [[ ${_GET_OS_TYPE} =~ 'CYGWIN_NT' ]];then
  # Windows only supports a single postgres instance so all the TLS certs will be from the domain
  # for cygwin.  Create in the 'domain' pki
  create_client "domain" "acme.com" "ACME Corp LLC" participant1
  create_client "domain" "acme.com" "ACME Corp LLC" participant2
fi

create_server_cert "participant1" "customer1.com" "Customer1 LLC" participant1
verify_cert "participant1" "customer1.com" participant1
create_server_cert "participant1" "customer1.com" "Customer1 LLC" auth
create_server_cert "participant1" "customer1.com" "Customer1 LLC" db
create_server_cert "participant1" "customer1.com" "Customer1 LLC" json
create_client "participant1" "customer1.com" "Customer1 LLC" admin-api
create_client "participant1" "customer1.com" "Customer1 LLC" participant1

create_server_cert "participant2" "customer2.com" "Customer2 LLC" participant2
create_server_cert "participant2" "customer2.com" "Customer2 LLC" auth
create_server_cert "participant2" "customer2.com" "Customer2 LLC" db
create_server_cert "participant2" "customer2.com" "Customer2 LLC" json
create_client "participant2" "customer2.com" "Customer2 LLC" admin-api
create_client "participant2" "customer2.com" "Customer2 LLC" participant2


echo "Complete making the certificates"
