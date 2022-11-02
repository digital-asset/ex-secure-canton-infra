#!/bin/bash

source env.sh

# This should work and return JWKS JSON
curl -s --resolve "auth.customer1.com:$JWTISSUER_1_PORT:127.0.0.1" --cacert ./certs/participant1/intermediate/certs/ca-chain.cert.pem -HHost:auth.customer1.com -HContent-Type:application/json -X GET https://auth.customer1.com:$JWTISSUER_1_PORT/.well_known/jwks.json
echo ""

# This should fail - Get token for Alice - as Alice is not set up yet.
curl -s --resolve "auth.customer1.com:$JWTISSUER_1_PORT:127.0.0.1" --cacert ./certs/participant1/intermediate/certs/ca-chain.cert.pem -HHost:auth.customer1.com -d '{"client_id":"alice123456","client_secret":"ComplexPassphrase!","grant_type":"client_credentials","audience":"alice"}' -HContent-Type:application/json https://auth.customer1.com:$JWTISSUER_1_PORT/auth
echo ""

# Setup Participant1
PARTICIPANT_ID=`cat data/participant1.txt`
CONFIG_DATA=`python3 setup-accounts.py accounts.json participant1 $PARTICIPANT_ID data/parties.txt`
echo "$CONFIG_DATA" | jq .

curl -s --resolve "auth.customer1.com:$JWTISSUER_1_PORT:127.0.0.1" --cacert ./certs/participant1/intermediate/certs/ca-chain.cert.pem -HHost:auth.customer1.com -d "$CONFIG_DATA" -HContent-Type:application/json https://auth.customer1.com:$JWTISSUER_1_PORT/configure
echo ""

# Setup Participant2
PARTICIPANT_ID=`cat data/participant2.txt`
CONFIG_DATA=`python3 setup-accounts.py accounts.json participant2 $PARTICIPANT_ID data/parties.txt`
echo "$CONFIG_DATA" | jq .

curl -s --resolve "auth.customer2.com:$JWTISSUER_2_PORT:127.0.0.1" --cacert ./certs/participant2/intermediate/certs/ca-chain.cert.pem -HHost:auth.customer2.com -d "$CONFIG_DATA" -HContent-Type:application/json https://auth.customer2.com:$JWTISSUER_2_PORT/configure
echo ""

curl -s --resolve "auth.customer1.com:$JWTISSUER_1_PORT:127.0.0.1" --cacert ./certs/participant1/intermediate/certs/ca-chain.cert.pem -HHost:auth.customer1.com -d '{"client_id":"alice123456","client_secret":"ComplexPassphrase!","grant_type":"client_credentials","audience":"alice"}' -HContent-Type:application/json https://auth.customer1.com:$JWTISSUER_1_PORT/auth
echo ""

curl -s --resolve "auth.customer2.com:$JWTISSUER_2_PORT:127.0.0.1" --cacert ./certs/participant2/intermediate/certs/ca-chain.cert.pem -HHost:auth.customer2.com -d '{"client_id":"bob123456","client_secret":"ComplexPassphrase!","grant_type":"client_credentials","audience":"bob"}' -HContent-Type:application/json https://auth.customer2.com:$JWTISSUER_2_PORT/auth
echo ""

curl -s --resolve "auth.customer2.com:$JWTISSUER_2_PORT:127.0.0.1" --cacert ./certs/participant2/intermediate/certs/ca-chain.cert.pem -HHost:auth.customer2.com -d '{"client_id":"bank123456","client_secret":"ComplexPassphrase!","grant_type":"client_credentials","audience":"bank"}' -HContent-Type:application/json https://auth.customer2.com:$JWTISSUER_2_PORT/auth
echo ""

curl -s --resolve "auth.customer2.com:$JWTISSUER_2_PORT:127.0.0.1" --cacert ./certs/participant2/intermediate/certs/ca-chain.cert.pem -HHost:auth.customer2.com -d '{"client_id":"george123456","client_secret":"ComplexPassphrase!","grant_type":"client_credentials","audience":"george"}' -HContent-Type:application/json https://auth.customer2.com:$JWTISSUER_2_PORT/auth
echo ""




