# Testing OCSP Based Certificate Revocation

**THIS IS A WORK-IN-PROGRESS**

- TODO: Enable OCSP checking on Domain
- TODO: Test OCSP Stapling for Domain and Participant
- TODO: Think about HA Testing

**IMPORTANT**: This repo is a demonstration of the capability. The OpenSSL OCSP Responder is useful for testing. It is 
recommended that production grade PKI (for example Java based EJBCA) is used for production environments. 
If an OCSP responder is down for a PKI then client will hang and access will be denied.

This example includes:
- OCSP Responder for Domain and Participant1 Root and Intermediate PKI CAs.
- Enables OCSP on Participant1 and debug logging (high volume).
- Provides a test client application to test against Participant1 Ledger API.
- OCSP Responder ports are configured in env-ports.sh to allow reconfiguration (Note: OCSP Responder URL, inc ports, is 
added to all certificates)

Out of Scope:
- Testing of revocation in an HA environment or through load-balancers

Testing Notes:
- If an OCSP responder is down for a PKI then applications may hang or access is denied
- OpenSSL OCSP Responder does not refresh from the CA certificate DB until process restart. This
demo is set up to have the responder listen as one process and exit immediately and then 
restarts a new copy. In a more heavily used PKI CA it might be expected that the responder 
would cycle through processes more frequently and not need this refresh process.
- To shutdown OpenSSL based OCSP responders use ```kill -9 <pid>``` or if
you are running the script then ```./kill-ocsp.sh```. This latter option set a 
flag (a file) and this drops the OCSP out of a repeat loop. OpenSSL OCSP Responder dow not 
respond to CTRL-C

```aidl
./cleanup-all.sh
./build.sh
./make-certs.sh
./make-jwt.sh
./start-postgres-domain.sh
./start-postgres-participant1.sh
./start-postgres-participant2.sh

# Start OCSP Responders for each CA
./start-domain-root-ocsp.sh
./start-domain-ocsp.sh
./start-p1-root-ocsp.sh
./start-p1-ocsp.sh
# NOTE: Config for Participant2 has not been created

# In start-participant1.sh enable OCSP features through environment variable

./start-participant1.sh

./start-participant2.sh
```

During startup and any connection over TLS, you should see a large volume of data dumped about
the TLS connectivity and from the Java PKI validation libraries.

# Scala Client to Test OCSP to Ledger API

This example:
- Creates a test client certificate
- Validate certificate against OCSP Responder
- Builds a Scala client application
- Connects to Ledger API on Participant1 with mTLS and JWT
- Dumps out value of Ledger API version from connected version
- Revokes certificates in Participant1 PKI (reason: keyCompromise)
- Attempts another connection from Ledger App and it fails due to revoked certificate

```aidl
./test-p1-ocsp.sh
```

**Copyright (c) 2024 Digital Asset (Switzerland) GmbH and/or its affiliates. All rights reserved.
SPDX-License-Identifier: Apache-2.0**
