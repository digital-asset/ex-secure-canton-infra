# Testing using Daml Script and REPL

This provides an example of using Daml Script and REPL consoles to access participants.

The Daml REPL and Canton REPL are separate and different. Daml REPL exposes a Daml console and is part of the SDK. The
Canton REPL console is provided as part of Canton and exposes a Scala based administration console of
Canton based nodes.  The prior exercise used the Canton REPL console.

**NOTE: If you ran the local testing example, you may want to wipe and rebuild environment. The domain will continue to run 
without issue but you will see the Parties created in local testing as well as those created through Scripts.**  

## Daml Script Testing
To allow setup and testing we use Daml Scripts. This is run using ```./test-script.sh```. 

The test script performs the following sequence:
- As an admin, get the list of participant Id's
- On each participant, as a local admin, set up local users and parties
- run workflow including upload of Dar to each participant and then each step of the "Canton Examples" flow

The main features to review include:
- use of Daml data structure and ```--input-file``` and ```--output-file``` to capture and pass 
parameters between steps
  - Data is json formatted DAML-LF structure and is passed in or returned based on Script functions
- allocate users and parties once and reuse in subsequent steps (Many of the example scripts in the Documentation recreate 
new parties on each run)
- lookup of existing contracts from previous steps (as these are not directly passed between functions)
- need to consider how to find and lookup data in a segregated participant model. Much of the Documentation assumes that
there is a shared console or shared variable from previous steps. 

Daml SDK parameters to connect securely to a participant node.
```angular2html
  daml script --dar ./dars/SecureDaml.dar \
    --script-name Workflow:bankIou \
    --ledger-host localhost --ledger-port 10021 \
    --access-token-file=${ROOTDIR}/certs/participant2/jwt/bank.token \
    --application-id "bank" \
    --tls --pem ${ROOTDIR}/certs/participant2/client/admin-api.customer2.com.key.pem \
    --crt ${ROOTDIR}/certs/participant2/client/admin-api.customer2.com.cert.pem \
    --cacrt "${ROOTDIR}/certs/participant2/intermediate/certs/ca-chain.cert.pem" \
    --input-file ./data/parties.txt \
    --output-file ./data/iou_contract.txt
```

## REPL Testing

To support using Daml REPL in a separate participant environment, we have created a
```./start-repl.sh <p1|p2|alice|bob|bank>``` utility to allow proper connection to each participant. This sets 
approproate values for the mTLS certificates and trust, along with the JWT token for the
relevant user context.

```angular2html
#!/bin/bash
# Copyright (c) 2020 Digital Asset (Switzerland) GmbH and/or its affiliates. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

source env.sh

run_repl() {
local namespace=$1
local prefix=$2
local port=$3
local DOMAIN=$4
local user=$5

CLIENT_CERT_AUTH=TRUE
CLIENT_CERT_PARAM=""
if [ "$CLIENT_CERT_AUTH" == "TRUE" ] ; then
echo "Enabling Client Certificate Auth"
CLIENT_CERT_PARAM="--pem ${ROOTDIR}/certs/$namespace/client/admin-api.$DOMAIN.key.pem --crt ${ROOTDIR}/certs/$namespace/client/admin-api.$DOMAIN.cert.pem "
fi

AUTH_TOKEN=`cat "${ROOTDIR}/certs/$namespace/jwt/$user.token"`
./decode-jwt.sh "${ROOTDIR}/certs/$namespace/jwt/$user.token"

daml repl ./dars/SecureDaml.dar \
--import ex-secure-canton-infra-0.0.1 \
--ledger-host localhost --ledger-port $port \
--access-token-file=${ROOTDIR}/certs/$namespace/jwt/$user.token \
--application-id "$user" \
--tls $CLIENT_CERT_PARAM \
--cacrt "${ROOTDIR}/certs/$namespace/intermediate/certs/ca-chain.cert.pem"

}

if [ $1 == "p1" ] ; then
run_repl participant1 p1 10011 customer1.com p1-admin
fi

if [ $1 == "p2" ] ; then
run_repl participant2 p2 10021 customer2.com p2-admin
fi

if [ $1 == "bank" ] ; then
run_repl participant2 p2 10021 customer2.com bank
fi

if [ $1 == "bob" ] ; then
run_repl participant2 p2 10021 customer2.com bob
fi

```

### Useful REPL commands

Some useful REPL commands for finding users and parties are listed below:

```angular2html
# User commands
aliceId <- validateUserId "alice"
aliceUser <- getUser aliceId

# Get a User's rights
listUserRights aliceId

currentRights <- listUserRights aliceId
debug currentRights

# Grant ParticipantAdmin Right to user
grantUserRights aliceId $ currentRights ++ [ParticipantAdmin]

# Revoke ParticipantAdmin from user
revokeUserRights aliceId $ [ParticipantAdmin]

# Get default participant_admin account and rights (only [ParticipantAdmin]
partAdmin <- validateUserId "participant_admin"
listUserRights partAdmin

# List all users
forA allUsers $ \user -> debug user


# Parties

# List all Known Parties
lkp <- listKnownParties
debug lkp

# Find a specific Party ID when you have set display names
# Only works with token with Admin rights
Some aliceDetails <- find (\d -> d.displayName == Some "Alice") <$> listKnownParties
aliceDetails.party

# Create a party from the text representation
# Note that you may need to use the full Canton party ID format "party-<random>::<namespace-fingerprint>. This can be obtained from the Script output above
    
Some alice <- pure $ partyFromText "Alice"

```

Next: [HA Testing](./test-ha.md)

**Copyright (c) 2022 Digital Asset (Switzerland) GmbH and/or its affiliates. All rights reserved.
SPDX-License-Identifier: Apache-2.0**

