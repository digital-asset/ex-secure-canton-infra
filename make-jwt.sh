#!/bin/bash
# Copyright (c) 2022 Digital Asset (Switzerland) GmbH and/or its affiliates. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

source env.sh

# https://gist.github.com/indrayam/dd47bf6eef849a57c07016c0036f5207

if [ ! -d certs ] ; then
   echo "Make certs first"
   exit 1
fi

if [ ! -d certs/participant1/jwt ] ; then
mkdir certs/participant1/jwt
mkdir certs/participant1/signing
fi 

if [ ! -d certs/participant2/jwt ] ; then
mkdir certs/participant2/jwt
mkdir certs/participant2/signing
fi 

# source env.sh
ROOTDIR="$(pwd)"
# On MacOS use brew installed openssl 1.1.1
export PATH=/usr/local/opt/openssl/bin:$PATH

ISSUE_DATE=`date "+%s"`
EXPIRY_DATE=$((`date "+%s"` +24*60*60 ))
APPLICATION_ID="ex-secure-canton-infra"

make_jwt_signing() {
  local DOMAIN=$1
  local DOMAIN_NAME=$2
  local namespace=$3

  echo " Generating local signing key JWT"
  openssl genpkey -out $ROOTDIR/certs/$namespace/signing/jwt-sign.$DOMAIN.key.pem -algorithm RSA -pkeyopt rsa_keygen_bits:2048
  openssl req -new -key $ROOTDIR/certs/$namespace/signing/jwt-sign.$DOMAIN.key.pem \
      -subj "/C=US/ST=New York/O=$DOMAIN_NAME/CN=jwt-sign.$DOMAIN" \
      -out $ROOTDIR/certs/$namespace/signing/jwt-sign.$DOMAIN.csr.pem

      #-addext "subjectAltName = DNS:jwt-sign.$DOMAIN, IP:127.0.0.1" \

  # Sign Client Cert
  openssl ca -batch -config $ROOTDIR/certs/$namespace/intermediate/openssl.cnf \
      -extensions sign_cert -notext -md sha256 \
      -in $ROOTDIR/certs/$namespace/signing/jwt-sign.$DOMAIN.csr.pem \
      -out $ROOTDIR/certs/$namespace/signing/jwt-sign.$DOMAIN.cert.pem

  # Validate cert is correct
  openssl verify -CAfile $ROOTDIR/certs/$namespace/intermediate/certs/ca-chain.cert.pem \
      $ROOTDIR/certs/$namespace/signing/jwt-sign.$DOMAIN.cert.pem
}

make_jwks() {
  local DOMAIN=$1
  local namespace=$2
  echo "Creating JKWS for local signer..."
  FINGERPRINT=`openssl x509 -in $ROOTDIR/certs/$namespace/signing/jwt-sign.$DOMAIN.cert.pem -fingerprint -sha1`
  SIGNING_DER=`openssl x509 -in $ROOTDIR/certs/$namespace/signing/jwt-sign.$DOMAIN.cert.pem -outform DER | base64 `
  INTERMEDIATE_DER=`openssl x509 -in $ROOTDIR/certs/$namespace/intermediate/certs/intermediate.cert.pem -outform DER | base64 `
  ROOT_DER=`openssl x509 -in $ROOTDIR/certs/$namespace/root/certs/ca.cert.pem -outform DER | base64 `

  which python3
  python3 --version
  python3 make-jwks.py $namespace $DOMAIN "$FINGERPRINT" "$SIGNING_DER" "$INTERMEDIATE_DER" "$ROOT_DER"
}

base64_padding()
{
  local len=$(( ${#1} % 4 ))
  local padded_b64=''
  if [ ${len} = 2 ]; then
    padded_b64="${1}=="
  elif [ ${len} = 3 ]; then
    padded_b64="${1}="
  else
    padded_b64="${1}"
  fi
  echo -n "$padded_b64"
}

base64url_to_b64()
{
  base64_padding "${1}" | tr -- '-_' '+/'
}

  #   PAYLOAD_TEMPLATE="{\"https://daml.com/ledger-api\": {\"ledgerId\": \"$LEDGER_ID\", \"admin\": $admin, \"actAs\": [$assctas], \"readAs\": [$actas]}, \"exp\": $EXPIRY_DATE, \"aud\": \"https://daml.com/ledger-api\", \"azp\": \"$1\", \"iss\": \"local-jwt-provider\", \"iat\": $ISSUE_DATE, \"gty\": \"client-credentials\", \"sub\": \"$user@clients\" }"
  #   PAYLOAD_TEMPLATE="{\"https://daml.com/ledger-api\": {\"ledgerId\": \"$LEDGER_ID\", \"applicationId\": \"$app\", \"admin\": $admin, \"actAs\": [$actas], \"readAs\": [$actas]}, \"exp\": $EXPIRY_DATE, \"aud\": \"https://daml.com/ledger-api\", \"azp\": \"$1\", \"iss\": \"local-jwt-provider\", \"iat\": $ISSUE_DATE, \"gty\": \"client-credentials\", \"sub\": \"$user@clients\" }"

make_user_jwt() {
  local user=$1
  local participant=$2
  echo "Making JWT Token for User $user"

  KEY_ID=`cat "$(pwd)/certs/$namespace/jwt/jwks.json" | jq .keys[0].kid | tr -d '"'`
  HEADER_TEMPLATE="{\"alg\":\"RS256\",\"typ\":\"JWT\", \"kid\": \"$KEY_ID\" }"
  HEADER=`echo -n $HEADER_TEMPLATE | openssl base64 -e -A | tr -- '-_' '+/' | sed -E s/=+$//`

  if [ "" == "$participant" ] ; then 
     PAYLOAD_TEMPLATE="{\"exp\": $EXPIRY_DATE, \"scope\": \"daml_ledger_api\", \"iss\": \"local-jwt-provider\", \"iat\": $ISSUE_DATE, \"sub\": \"$user\" }"
  else
     PAYLOAD_TEMPLATE="{\"exp\": $EXPIRY_DATE, \"scope\": \"daml_ledger_api\", \"iss\": \"local-jwt-provider\", \"iat\": $ISSUE_DATE, \"sub\": \"$user\", \"aud\": \"$participant\" }"
  fi

  #echo $PAYLOAD_TEMPLATE
  #echo $SIGNING_KEY
  if [ ! -f /etc/os-release ] ; then
    # Guessing this is Darwin
    PAYLOAD=`echo -n "$PAYLOAD_TEMPLATE" | base64 | tr -- '+/' '-_' | sed -E s/=+$//`
  else
    PAYLOAD=`echo -n "$PAYLOAD_TEMPLATE" | base64 -w 0 | tr -- '+/' '-_' | sed -E s/=+$//`
  fi
  DIGEST=`echo -n "$HEADER.$PAYLOAD" | openssl dgst -sha256 -sign $SIGNING_KEY -binary | base64 | tr -d '\n=' | tr -- "+/" "-_"`
  JWT=$HEADER.$PAYLOAD.$DIGEST
  echo -n $JWT > certs/$namespace/jwt/$user.token
  #echo "$user Token: $JWT"
  #echo ""

  openssl x509 -pubkey -noout -in ${ROOTDIR}/certs/$namespace/signing/jwt-sign.$DOMAIN.cert.pem > ${ROOTDIR}/certs/$namespace/signing/jwt-sign.$DOMAIN.pub.pem
  input=${JWT%.*}
  echo -n $input > ./data/payload.txt
  #echo $input

  # Extract the signature portion
  encSig=${JWT##*.}
  #echo encSig

  # Decode the signature
  #echo $(base64url_to_b64 ${encSig})
  printf '%s' "$(base64url_to_b64 ${encSig})" | base64 -d > ./data/signature.dat

  #TEST=`echo -n "$HEADER.$PAYLOAD" | openssl dgst -sha256 -sign $SIGNING_KEY -binary`
  #echo -n "$HEADER.$PAYLOAD" > test.txt
  #echo -n "$TEST" > test-sig.bin
  #openssl dgst -sha256 -verify ${ROOTDIR}/certs/$namespace/signing/jwt-sign.$DOMAIN.pub.pem -signature test-sig.bin test.txt

  # Finally, verify
  openssl dgst -sha256 -verify ${ROOTDIR}/certs/$namespace/signing/jwt-sign.$DOMAIN.pub.pem -signature ./data/signature.dat ./data/payload.txt
  #Output should be "Verified OK"

}

make_custom_jwt() {
  local user=$1
  local app=$2
  local admin=$3
  local actas=$4
  local participant=$5
  echo "Making JWT Token for $user"

  KEY_ID=`cat "$(pwd)/certs/$namespace/jwt/jwks.json" | jq .keys[0].kid | tr -d '"'`
  HEADER_TEMPLATE="{\"alg\":\"RS256\",\"typ\":\"JWT\", \"kid\": \"$KEY_ID\" }"
  HEADER=`echo -n $HEADER_TEMPLATE | openssl base64 -e -A | tr -- '-_' '+/' | sed -E s/=+$//`

  # PAYLOAD_TEMPLATE="{\"https://daml.com/ledger-api\": {\"ledgerId\": \"$LEDGER_ID\", \"admin\": $admin, \"actAs\": [$actas], \"readAs\": [$actas]}, \"exp\": $EXPIRY_DATE, \"aud\": \"https://daml.com/ledger-api\", \"azp\": \"$1\", \"iss\": \"local-jwt-provider\", \"iat\": $ISSUE_DATE, \"gty\": \"client-credentials\", \"sub\": \"$user@clients\" }"

  #if [ ! "" == "$participant" ] ; then 
  #   AUDIENCE_VAR=", \"aud\": \"$participant\""
  #fi

  if [ "true" == "$admin" ] ; then
     ADMIN_VAR=", \"admin\": $admin"
  else
     ADMIN_VAR=""
  fi 

  if [ ! "" == "$actas" ] ; then 
     SUBJECT_VAR="\"actAs\": [$actas], \"readAs\": [$actas]"
  else 
     SUBJECT_VAR=""
  fi

  PAYLOAD_TEMPLATE="{\"https://daml.com/ledger-api\": { \"ledgerId\": \"$namespace\", $SUBJECT_VAR $ADMIN_VAR }, \"exp\": $EXPIRY_DATE, \"aud\": \"https://daml.com/ledger-api\", \"azp\": \"$1\", \"iss\": \"local-jwt-provider\", \"iat\": $ISSUE_DATE, \"gty\": \"client-credentials\" }"

  echo $PAYLOAD_TEMPLATE
  echo $SIGNING_KEY
  if [ ! -f /etc/os-release ] ; then
    # Guessing this is Darwin
    PAYLOAD=`echo -n "$PAYLOAD_TEMPLATE" | base64 | tr -- '+/' '-_' | sed -E s/=+$//`
  else
    PAYLOAD=`echo -n "$PAYLOAD_TEMPLATE" | base64 -w 0 | tr -- '+/' '-_' | sed -E s/=+$//`
  fi
  DIGEST=`echo -n "$HEADER.$PAYLOAD" | openssl dgst -sha256 -sign $SIGNING_KEY -binary | base64 | tr -d '\n=' | tr -- "+/" "-_"`
  JWT=$HEADER.$PAYLOAD.$DIGEST
  echo -n $JWT > certs/$namespace/jwt/$user.token
  #echo "$user Token: $JWT"
  #echo ""

  openssl x509 -pubkey -noout -in ${ROOTDIR}/certs/$namespace/signing/jwt-sign.$DOMAIN.cert.pem > ${ROOTDIR}/certs/$namespace/signing/jwt-sign.$DOMAIN.pub.pem
  input=${JWT%.*}
  echo -n $input > ./data/payload.txt
  #echo $input

  # Extract the signature portion
  encSig=${JWT##*.}
  #echo encSig

  # Decode the signature
  #echo $(base64url_to_b64 ${encSig})
  printf '%s' "$(base64url_to_b64 ${encSig})" | base64 -d > ./data/signature.dat

  #TEST=`echo -n "$HEADER.$PAYLOAD" | openssl dgst -sha256 -sign $SIGNING_KEY -binary`
  #echo -n "$HEADER.$PAYLOAD" > test.txt
  #echo -n "$TEST" > test-sig.bin
  #openssl dgst -sha256 -verify ${ROOTDIR}/certs/$namespace/signing/jwt-sign.$DOMAIN.pub.pem -signature test-sig.bin test.txt

  # Finally, verify
  openssl dgst -sha256 -verify ${ROOTDIR}/certs/$namespace/signing/jwt-sign.$DOMAIN.pub.pem -signature ./data/signature.dat ./data/payload.txt
  #Output should be "Verified OK"

}

DOMAIN="customer1.com"
namespace=participant1
DOMAIN_NAME="Customer1, LLC"
SIGNING_KEY=${ROOTDIR}/certs/$namespace/signing/jwt-sign.$DOMAIN.key.pem
LEDGER_ID="participant1"
if [ ! -f "$SIGNING_KEY" ] ; then
  make_jwt_signing $DOMAIN "$DOMAIN_NAME" $namespace
  make_jwks $DOMAIN $namespace
fi
make_user_jwt "participant_admin" ""
if [ -f ./data/participants.txt ] ; then
  PARTICIPANT=`cat ./data/participants.txt | jq '.[].party' | grep participant1 | tr -d "\"" | tr -d ","`
  make_user_jwt "alice" $PARTICIPANT
  ALICE_PARTY=`cat data/parties.txt | jq .'alice' | tr -d '"'`
  make_custom_jwt "navigator" "" "true" " \"$ALICE_PARTY\" " $PARTICIPANT
fi

DOMAIN="customer2.com"
namespace=participant2
DOMAIN_NAME="Customer2, LLC"
SIGNING_KEY=${ROOTDIR}/certs/$namespace/signing/jwt-sign.$DOMAIN.key.pem
LEDGER_ID="participant2"
if [ ! -f "$SIGNING_KEY" ] ; then
  make_jwt_signing $DOMAIN "$DOMAIN_NAME" $namespace
  make_jwks $DOMAIN $namespace
fi
make_user_jwt "participant_admin" ""

if [ -f ./data/participants.txt ] ; then
  PARTICIPANT=`cat ./data/participants.txt | jq '.[].party' | grep participant2 | tr -d "\"" | tr -d ","`
  make_user_jwt "bob" $PARTICIPANT
  make_user_jwt "bank" $PARTICIPANT
  BOB_PARTY=`cat data/parties.txt | jq .'bob' | tr -d '"'`
  BANK_PARTY=`cat data/parties.txt | jq .'bank' | tr -d '"'`
  make_custom_jwt "navigator" "" "true" " \"$BOB_PARTY\",\"$BANK_PARTY\" " $PARTICIPANT
fi
