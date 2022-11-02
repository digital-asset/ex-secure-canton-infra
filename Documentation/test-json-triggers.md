# Testing JSON API and Triggers

In this section we demonstrate the use of JSON API and Triggers. To achieve this we have a new 
sample Daml model, consisting of:

- JSON API server behind a load-balancer proxy (Note: we only start one JSON API so not HA)
- Asset and DonorConfig models (see below)
- User Alice on Participant1 and Bob and George on Participant2
- A Daml Trigger which sends Assets from Bob to Alice
- A Python (dazl-client) trigger which sends from George to Bob
- A load test through JSON API to send assets to George

A Daml party sets up their "DonorConfig" to define who should receive any assets they receive.

## Steps to run demo

```aidl
# Start JSON API (in separate Windows)
./start-json-p1.sh
./start-json-p2.sh

# Start load-balancers
./start-lb-json-p1.sh
./start-lb-json-p2.sh

# Set up users and participants and retrieve details
./test-scripts.sh

# Setup Donor configs and some initial assets
./test-scripts2.sh

# Start the Daml triger for Bob
./start-trigger.sh

# Start the JWT Issuers and Python Bot
./start-jwt-auth-p1.sh
./start-jwt-auth-p2.sh
./setup-jwt.sh
./start-python-bot.sh

# Load data 
./test-load.sh
 
```
# Details of what is happening
## Asset / DonorConfig Daml Model

To demonstrate Triggers and JWT Authorization we use the following Daml Model:

```aidl
-- Copyright (c) 2018-2020, Digital Asset (Switzerland) GmbH and/or its affiliates.
-- All rights reserved.

module Main where

type AssetId = ContractId Asset
type ConfigId = ContractId DonorConfig
type AssetKey = (Party, Text)

template Asset
  with
    issuer : Party
    owner  : Party
    name   : Text
  where
    ensure name /= ""
    signatory issuer
    observer owner

    key (issuer, name) : AssetKey
    maintainer key._1

    choice Give: AssetId
      with
        newOwner : Party
      controller owner
        do
          create this with owner = newOwner

template DonorConfig
  with 
    owner: Party
    donateTo: Party
  where
    signatory owner
    observer owner

    key owner : Party
    maintainer key
```

The Asset template allows a party to create an Asset with an owner. If they are the current owner, a party can Give the 
Asset to another party. The help the Triggers we also define a DonorConfig template that says who the party will give the 
asset to by default. The Daml and Python triggers use this to configure themselves. The Daml trigger acts as Bob and hands 
all Assets to its defined destination (Alice) and the Python Trigger runs as George and similarly has a default destination
(George in this case). Thus to test, assets handed to George are given to Bob via Python trigger and then given to alice 
via the Daml trigger.

Bob's Daml Trigger looks like this:

```aidl
module BobTrigger where

import DA.Foldable
import Daml.Trigger
import Main

rejectTrigger : Trigger ()
rejectTrigger = Trigger
  { initialize = pure ()
  , updateState = \_message -> pure ()
  , rule = rejectRule
  , registeredTemplates = AllInDar
  , heartbeat = None
  }

rejectRule : Party -> TriggerA () ()
rejectRule p = do
  assets : [(ContractId Asset, Asset)] <- query @Asset
  -- Get all assets owned by Bob
  let bobAssets = filter (\(_,a) -> a.owner == p) assets
  -- get the DonorConfig record for Bon
  configs : [(ContractId DonorConfig, DonorConfig)] <- query @DonorConfig
  let Some (_,bobConfig) = find (\(_,c) -> c.owner == p) configs

  -- for all of Bob assets, give them to the donateTo (Alice) in the DonorConfig record
  forA_ bobAssets $ \(_cid, c) -> do
    debug "Ran rejectRule"
    emitCommands [exerciseCmd _cid Give with newOwner = bobConfig.donateTo] [toAnyContractId _cid]


```
The Python trigger is similar but involves a little more code:

```aidl
import logging
import datetime
import dazl
import sys
import asyncio
import requests
from dataclasses import dataclass, field

dazl.setup_default_logger(logging.INFO)
logging.basicConfig(filename='bot.log', level=logging.INFO)
EPOCH = datetime.datetime.utcfromtimestamp(0)

@dataclass
class Config:
  party: str
  oauth_token: str
  url: str
  ca_file: str
  cert_file: str
  cert_key_file: str

async def process_contracts(config: Config):
  #--application-name "ex-secure-daml-infra" --url "https://ledger.acme.com:6865" -
  # -cert-key-file "./certs/client/client1.acme.com.key.pem" --cert-file "./certs/client/client1.acme.com.cert.pem"
  # --ca-file "./certs/intermediate/certs/ca-chain.cert.pem" --oauth-client-id "george123456"
  # --oauth-client-secret "ComplexPassphrase!" --oauth-token-uri "https://auth.acme.com:4443/oauth/token"
  # --oauth-ca-file "./certs/intermediate/certs/ca-chain.cert.pem" --oauth-audience "https://daml.com/ledger-api"
  global donateTo

  async with dazl.connect(url=config.url,
                          ca_file=config.ca_file,
                          cert_key_file=config.cert_key_file,
                          cert_file=config.cert_file,
                          oauth_token=config.oauth_token
                          ) as conn:

    async for event in conn.stream("Main:Asset").creates():

      if isinstance(event, dazl.ledger.api_types.CreateEvent):
        logging.info(event.payload)
        if event.payload['owner'] == config.party:
          logging.info("New asset created for {}: {}".format(event.payload['owner'], event.payload['name']))

          if donateTo == None:
            logging.info("No DonorConfig for {}".format(event.payload['owner']))

          if donateTo != None and config.party != donateTo:
            logging.info(config.party + ' is exercising Give on ' + str(event.contract_id))
            await conn.exercise(event.contract_id, 'Give', {'newOwner': donateTo})

async def process_donor(config: Config):
  #--application-name "ex-secure-daml-infra" --url "https://ledger.acme.com:6865" -
  # -cert-key-file "./certs/client/client1.acme.com.key.pem" --cert-file "./certs/client/client1.acme.com.cert.pem"
  # --ca-file "./certs/intermediate/certs/ca-chain.cert.pem" --oauth-client-id "george123456"
  # --oauth-client-secret "ComplexPassphrase!" --oauth-token-uri "https://auth.acme.com:4443/oauth/token"
  # --oauth-ca-file "./certs/intermediate/certs/ca-chain.cert.pem" --oauth-audience "https://daml.com/ledger-api"
  global donateTo

  async with dazl.connect(url=config.url,
                          ca_file=config.ca_file,
                          cert_key_file=config.cert_key_file,
                          cert_file=config.cert_file,
                          oauth_token=config.oauth_token
                          ) as conn:

    async for event in conn.stream("Main:DonorConfig").creates():

      if isinstance(event, dazl.ledger.api_types.CreateEvent):
        logging.info(event.payload)
        if event.payload['owner'] == config.party:
          logging.info("DonorConfig for {}: {}".format(event.payload['owner'], event.payload['donateTo']))

          donateTo = event.payload['donateTo']

async def run_tasks(config: Config):

  task1 = asyncio.create_task(process_contracts(config))
  task2 = asyncio.create_task(process_donor(config))

  await task1
  await task2

donateTo = None

def main(argv):

  logging.info(argv)
  party = argv[0]
  application_id = argv[1]
  url = argv[2]
  ca_file = argv[3]
  cert_file = argv[4]
  cert_key_file = argv[5]
  oauth_client_id = argv[6]
  oauth_client_secret = argv[7]
  oauth_token_uri = argv[8]
  oauth_ca_file = argv[9]
  oauth_audience = argv[10]

  if oauth_audience == None:
    logging.error("ERROR: Need to supply an oAuth audience")
    return

  if oauth_ca_file == "None":
    oauth_ca_file = None

  headers = {"Accept": "application/json"}
  data = {
    "client_id": oauth_client_id,
    "client_secret": oauth_client_secret,
    "audience": oauth_audience,
    "grant_type": "client_credentials",
    "application_id": application_id
  }

  if oauth_token_uri is None:
    logging.error("Token URI not set")
    return

  response = None
  try:
    response = requests.post(
      oauth_token_uri,
      headers=headers,
      data=data,
      auth=None,
      verify=oauth_ca_file,
    )
  except Exception as ex:
    logging.info(ex)
    logging.error("Unable to get token at this time")
    return

  if response.status_code != 200:
    logging.error("ERROR: Unable to retrieve token. Exiting")
    return

  json = response.json()
  oauth_token = json['access_token']

  config = Config(party,oauth_token, url, ca_file, cert_file, cert_key_file)

  logging.info(config.oauth_token)

  asyncio.run(run_tasks(config))

if __name__ == '__main__':
  main(sys.argv[1:])
```


## JWT Issuers

The JWT Issuers allow an application to authenticate and retrieve a JWT token. This is used in this
demo by the Python trigger. 

Specific details of the JWT Issuers include:

- JWT starts up with a signing and TLS key (for HTTPS)
- Ledger can be pointed at the JWKS endpoint (https://<jwt-issuer-server>:<port>/.well_known/jwks.json) 
- JWT starts with a default config of one user (```participant_admin```). A script (```./setup-jwt-issuer.sh```) is used to 
setup new map users in the JWT Issuer (there is one issuer per participant) and this uploads through ```/configure``` endpoint 
to initialize the service. More details below.
- Once setup, the JWT Issuer is ready to issue tokens for the application, each signed by the signing key
- Apps should post to https://<jwt-issuer-server>:<port>/auth endpoint passing in credentials of user to authenticate (see 
```./test-jwt.sh``` and ```./get-jwt.sh```for exact format for this call)

An example of a JWKS:

```aidl
{  "keys": [
    {
      "e": "AQAB",
      "kid": "Syqfas9yN3erg09EtpZ-5LTMeN40Zn5Q0vu0bNyoknw",
      "kty": "RSA",
      "n": "yjIAS63Txb1rE7LHo4WKFHoyfU-S2U53Y6xC_ZQDqIffCa--MUQ1WQkFjkoYXr4NVfpbxHX7_S4HzeO_gerUnEx0IlyFEneZ8duGM35RAKhJa7IDq1drmO1uF1ED0qbgx2pqFYqlNDo0XVwTchXGX9Abh4CGBv3LlDkPnwts2skPBMcoEvFXvegNlO56S5DNpohQ539Bur0Y1gOB-24X0B8C8C3edcro3Eq-mzeXWvucN7umNalQhokvc1d5DUN7bN_Dr3cbfOX7hlQJjXPRXrd6CIEjWUOR8OpILC4nS7RV8sru2D7-gUdX5SQJYPdveJwX5dObj85M9CtSGQMOVw",
      "alg": "RS256",
      "use": "sig",
      "x5t": "QTAzQTMxMjcyRkEyOEEwMTdGOUM0NDhBMEM5ODBFOTBCRjBEOTc4Qg==",
      "x5c": [
        "MIIFETCC<rest-of-cert in BASE64 DER encoding>",
        "MIIF5TCC<rest-of-cert in BASE64 DER encoding>",
        "MIIF+TCC<rest-of-cert in BASE64 DER encoding>"
      ]
    }
  ]
```

where:
- kid - Key ID
- e,n - RSA parameters of the certificate
- kty - key type - RSA in this instance
- alg - signing algorithm - RSA with SHA256 
- use - usage - signature in this case
- x5t - Certificate fingerprint
- x6c - Certificate chain array with signing key, intermediate and root certificates

A JWT (when encoded) will look like the following (one string formatted for clarity):

```aidl
eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCIsICJraWQiOiAiU3lxZmFzOXlOM2VyZzA5RXRwWi01TFRNZU40MFpuNVEwdnUwYk55b2tudyIgfQ
  .eyJleHAiOiAxNjY2NzA0NTkyLCAic2NvcGUiOiAiZGFtbF9sZWRnZXJfYXBpIiwgImlzcyI6ICJsb2NhbC1qd3QtcHJvdmlkZXIiLCAiaWF0IjogMTY2NjYxODE5MiwgInN1YiI6ICJwYXJ0aWNpcGFudF9hZG1pbiIgfQ
  .kbfyqfFn1yayNCemz0tXgUQ_yvvkwbJ17F7TohB5RQS2YUzvpvuSR2b-bNc1Y5PpaNwZGdsfvMS_ITDhVIM00RlNUiFpd9qNPVdnfQaWFfBdVu-ZJWA8bsBGYp7-lSdSzxox0MKFAlXV2NRivBRXtKCnVIiFCwSeJj-89fzqZn_DCp3PEJI8_bc-mCuQ2_06mSeUCfB080UHktmRxIULUzsZiGFVmi50sMnBqSeV8p6jN86b5mupxB5xJWlbbRTQt529XhHZv8XohkXD0rVIi4EXKVcNqRZuW2cobEavDZfasLA20eHlR33U_wDR4hhdZZuUkHRg-S9aYsadRykmsQ
```
in the format HEADER.PAYLOAD.SIGNATURE, which when decoded becomes

```
{
"alg": "RS256",
"typ": "JWT",
"kid": "Syqfas9yN3erg09EtpZ-5LTMeN40Zn5Q0vu0bNyoknw"
}
{
"exp": 1666704592,
"scope": "daml_ledger_api",
"iss": "local-jwt-provider",
"iat": 1666618192,
"sub": "participant_admin"
}
```
with the issue at date (iat) and expiry date (exp) in UNIX time format  (seconds since Jan 1 1970). The signature is not 
decoded as it is a binary format. 

See original [Secure Canton Reference App](https://github.com/digital-asset/ex-secure-canton-infra) for explanation of JWT 
and JWKS formats.

### Why do you need a JWT Issuer setup step?

The JWT Issuer service needs to be told the participant ID of the participant and the users it is issuing for. By default,
a new participant only has one User defined - ```participant_admin```. As you create new users and parties in the participant,
the JWT service needs to be told about these so that it can issue appropriate JWT tokens. For the demo with this Ref App we 
configure the following:

- Participant1 - Alice
- Participant2 - Bob, Bank, George

After these are configured, we then define records for the users and upload to the JWT issuer with the relevant Participant
Namespace ID. The participant namespace ID is set as the audience ("aud") field to restrict access to the specific participant.

```aidl
{
    "alg": "RS256",
    "typ": "JWT",
    "kid": "Syqfas9yN3erg09EtpZ-5LTMeN40Zn5Q0vu0bNyoknw"
}
{
    "exp": 1666709262,
    "scope": "daml_ledger_api",
    "iss": "local-jwt-provider",
    "iat": 1666622862,
    "sub": "alice",
    "aud": "participant1::12203f1536c10be26d7ecc8602fef7ca0c9145bd2438772d1dc0622ee2c607b72d7c"
}
```
In some situations (minor issue with Navigator and user token auth), you may need to use legacy format tokens, which includes
the party ID rather than a user ID. 

```aidl
{
    "alg": "RS256",
    "typ": "JWT",
    "kid": "Syqfas9yN3erg09EtpZ-5LTMeN40Zn5Q0vu0bNyoknw"
}
{
    "https://daml.com/ledger-api": {
        "ledgerId": "participant1",
        "actAs": [
            "party-02a0ff35-4e3c-46de-abf6-c916e2d0a1bf::12203f1536c10be26d7ecc8602fef7ca0c9145bd2438772d1dc0622ee2c607b72d7c"
        ],
        "readAs": [
            "party-02a0ff35-4e3c-46de-abf6-c916e2d0a1bf::12203f1536c10be26d7ecc8602fef7ca0c9145bd2438772d1dc0622ee2c607b72d7c"
        ],
        "admin": true
    },
    "exp": 1666709262,
    "aud": "https://daml.com/ledger-api",
    "azp": "navigator",
    "iss": "local-jwt-provider",
    "iat": 1666622862,
    "gty": "client-credentials"
}
```

**Copyright (c) 2022 Digital Asset (Switzerland) GmbH and/or its affiliates. All rights reserved.
SPDX-License-Identifier: Apache-2.0**

