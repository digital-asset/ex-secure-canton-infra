#!/bin/bash
# Copyright (c) 2022 Digital Asset (Switzerland) GmbH and/or its affiliates. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

source env.sh

export POSTGRES_USER=participant1
export POSTGRES_PASSWORD=Participant1Password!
export POSTGRES_HOST=localhost
export POSTGRES_PORT=5433
export POSTGRES_MAX_CONNECTIONS=8

export POSTGRES_SSL=true
export POSTGRES_SSLMODE=verify-full
export POSTGRES_SSLROOTCERT="certs/participant1/intermediate/certs/ca-chain.cert.pem"
export POSTGRES_SSLCERT="certs/participant1/client/participant1.customer1.com.cert.der"
export POSTGRES_SSLKEY="certs/participant1/client/participant1.customer1.com.key.der"
export POSTGRES_URL="jdbc:postgresql://$POSTGRES_HOST:$POSTGRES_PORT/participant1?user=participant1&password=Participant1Password!&ssl=true&sslmode=verify-full&sslrootcert=$ROOTDIR/certs/participant1/intermediate/certs/ca-chain.cert.pem&sslcert=$ROOTDIR/certs/participant1/client/participant1.customer1.com.cert.der&sslkey=$ROOTDIR/certs/participant1/client/participant1.customer1.com.key.der"

export JWKS_URL="file://${ROOTDIR}/certs/participant1/jwt/jwks.json"

export PARTICIPANT_TOKEN=`cat certs/participant1/jwt/participant_admin.token`

# The following option is used as part of OCSP Certificate revocation checking
OCSP_CHECKING=""
#OCSP_CHECKING="TRUE"

ENABLE_DEBUG=""

if [ "$OCSP_CHECKING" != "" ]; then
  ENABLE_DEBUG=" -v --debug "
  echo "Enabling OCSP Checking for Participant"
  if [ ! -f jSSLKeyLog-1.3.zip ] ; then
     curl -L https://github.com/jsslkeylog/jsslkeylog/releases/download/v1.3.0/jSSLKeyLog-1.3.zip -o jSSLKeyLog-1.3.zip
  fi
  unzip -o jSSLKeyLog-1.3.zip jSSLKeyLog.jar
  export JAVA_OCSP=(--show-version -Djava.security.properties=file://./java.security -javaagent:$ROOTDIR/jSSLKeyLog.jar=log/jssl-key.log -Djava.security.debug=\"certpath ocsp\" -Djavax.net.debug=\"ssl:handshake\" -Djava.security.properties=$ROOTDIR/java.security -Dcom.sun.net.ssl.checkRevocation=true -Djdk.tls.client.enableStatusRequestExtension=true -Djdk.tls.server.enableStatusRequestExtension=true -Djavax.net.ssl.trustStore=$ROOTDIR/certs/participant1/intermediate/certs/local-truststore.jks -Djavax.net.ssl.trustStorePassword=changeit)
else
  # Horrible hack as command below fails if Bash array is empty. Effective no-op to show Java version and continue
  JAVA_OCSP=(--show-version)
fi

#echo ${JAVA_OCSP[@]}
export JAVA_OPTS="$JAVA_OPTS "${JAVA_OCSP[@]}
#echo "$JAVA_OPTS"

$CANTON_DIR/bin/canton $RUN_AS_DAEMON $ENABLE_DEBUG --log-file-name log/participant1.log -c configs/mixins/api/jwt/jwks.conf -c configs/mixins/api/public.conf -c configs/mixins/api/public-admin.conf -c configs/mixins/parameters/nonuck.conf -c configs/mixins/storage/postgres.conf -c configs/participant/participant1.conf --bootstrap configs/participant/participant-init.canton
