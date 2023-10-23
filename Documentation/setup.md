# Setup of Domain and Participants

This phase sets up the Canton Domain components and the connects each participant to the 
domain. All components are enabled for (m)TLS and JWT as appropriate and shows 
how to configure a fully secure Canton setup. 

## Pre-requisites

- This has been tested on MacOS Monterey and Ubuntu Linux with Java OpenJDK (Zulu) 11
- This has been tested with Daml SDK 2.7.4 and Daml Community and Enterprise 2.7.4
- Ensure you have Python3 installed
  - This may no longer be installed on MacOS Monterey or later
  - run ```brew install python```
- Ensure you have Python jwcrypto library installed
  - ```pip3 install jwcrypto```
- Install openssl (as Apple openssl (LibreSSL) is missing some options)
  - ```brew install openssl@3```
- Install JQ for JSON parsing
  - ```brew install jq```
- Install Docker Desktop or equivalent (Podman) to execute PostgresQL DBs

## Download Daml SDK

Install SDK by following steps in documentation: https://docs.daml.com/getting-started/installation.html 

Download copy of the Canton artifacts
- Community - https://github.com/digital-asset/daml and download canton-community-2.7.4.tar.gz
- Enterprise - Please contact Digital Asset (sales@digitalasset.com) for details.

The Canton version is determined by setting the environment variable
CANTON_DIR to the root of the Canton installation.  A default is
hardcoded in env.sh.  For example, if canton is unzipped with the path
```~/src/canton-enterprise-2.7.4``` then "```export
CANTON_DIR=~/src/canton-enterprise-2.7.4```".

## Clean and build base environment

This step includes:

- wipe of all Docker based Postgres instances (cleanup-all.sh)
- Build test dar (build.sh)
- Build a Root and Intermediate CA for each PKI instance (domain, participant1 and participant2) (make-cert.sh)
- Create JWT Signing keys for each participant and a JKWS (public key distribution via JSON) and then 
JWT tokens for each user on each participant. (make-jwt.sh)
- Start Domain and Participants in secure mode (start-* scripts)

Please read the section on [User and Party Management](./user-management.md) to get more in-depth details on 
how users and parties are managed in Daml and the associated JWT formats.

```angular2html
# WARNING: This step clears any Postgres backing stores and deletes PKI
./cleanup-all.sh

# Build the Daml dars for the example (Canton Example Iou and Paint)
./build.sh

# Make the PKI CA (2 tier - Root and Intermediate) for Domain, Participants 1 & 2
./make-certs.sh

# Make relevant JWT Signing keys under each Participant CA and JWKS, along with 
# JWT tokens
# Script can be re-run to refresh the JWT tokens (one day expiry)
./make-jwt.sh
```

## To Start the Domain

NOTE: the Postgres (PG) start scripts includes a PG initialization script (see pg_init directory) that creates a 
separate PG account and database so that the services are not access as Postgres account directly.

### Single Domain Node (Community)

For Community edition, this brings up a consolidated domain, which includes a sequencer, 
mediator and domain manager node sharing a common Postgres database.
```
./start-postgres-domain.sh
./start-domain.sh
```

### Distributed Multi-Node (non-HA) Domain (Enterprise)

This option is available to Enterprise license customers. Enterprise Edition allows the separation of the 
Domain components to run as their separate process and also allows for High-Availability (HA) options. Enterprise Edition supports the 
use of other DLT technologies (Fabric, Besu, Corda) as the seqeuncer backends to provide for alternative trust models (ones where a single central 
"trusted" domain operator is not expected).
```
./start-postgres-domain.sh
# In separate Terminal window
./start-sequencer.sh
# In separate Terminal window
./start-mediator.sh
# In separate Terminal window
./start-domain-manager.sh
# In separate Terminal window
./start-remote-domain.sh
```

Specific items to look for in start-* scripts include:
- ability to run a service in [daemon](https://docs.daml.com/canton/usermanual/command_line.html#daemon) (no console)
- ability to use [HOCON](https://docs.daml.com/canton/usermanual/static_conf.html#static-configuration) mixins to tailor features (Postgres, certs, JWT auth, etc)
- [bootstrap](https://docs.daml.com/canton/tutorials/getting_started.html#automation-using-bootstrap-scripts) code to auto-initialize a domain

#### Domain startup initialisation
Once the domain has come up you need to run the following command to initialize the domain.  These commands are entered and executed by the remote donain console.  To open the remote domain console, enter this command from
a new shell window using the ```start-remote-domain.sh``` (non-HA) or ```start-remote-domain-ha.sh``` (HA) scripts.

Once the console has initialized, proceed as follows:

```
# On Remote Admin Management console
# Start up domain by running
domain.setup.bootstrap_domain(sequencers.remote, Seq(mediator))
```

```angular2html
# THIS IS INDIVIDUAL STEPS FOR THE ABOVE - DOES NOT NEED TO BE RUN A SECOND TIME

# on Remote Admin Console
import com.digitalasset.canton.protocol.StaticDomainParameters
import com.digitalasset.canton.topology.store.StoredTopologyTransactions
import com.digitalasset.canton.sequencing.SequencerConnection

domain.service.get_static_domain_parameters.writeToFile("domain-params.bin")

val domainParameters = StaticDomainParameters.tryReadFromFile("domain-params.bin")
val domainId = domain.id
val initResponse = sequencer.initialization.initialize_from_beginning(domainId, domainParameters)

# HANGS
# initResponse.publicKey.writeToFile("sequencer-public-key.pem")
#val sequencerPublicKey = SigningPublicKey.tryReadFromFile(("sequencer-public-key.pem")

domain.setup.helper.authorizeKey(initResponse.publicKey,"sequencer",SequencerId(domainId))

mediator.keys.secret.generate_signing_key("initial-key").writeToFile("mediator-key.pem")

val mediatorKey = SigningPublicKey.tryReadFromFile("mediator-key.pem")

domain.setup.helper.authorizeKey(mediatorKey,"mediator",MediatorId(domainId))

# Error for curtis ALREADY_EXISTS/TOPOLOGY_MAPPING_ALREADY_EXISTS
domain.topology.mediator_domain_states.authorize(TopologyChangeOp.Add,domainId,MediatorId(domainId),RequestSide.Both)

domain.topology.all.list().collectOfType[TopologyChangeOp.Positive].writeToFile("domain-topology.bin")
val initialTopology = StoredTopologyTransactions.tryReadFromFile("domain-topology.bin").collectOfType[TopologyChangeOp.Positive]

sequencer.initialization.bootstrap_topology(initialTopology)

sequencer.sequencerConnection.writeToFile("sequencer-connection.bin")

val sequencerConnection = SequencerConnection.tryReadFromFile("sequencer-connection.bin")
val domainParameters = StaticDomainParameters.tryReadFromFile("domain-params.bin")

mediator.mediator.initialize(domainId,MediatorId(domainId),domainParameters,sequencerConnection,None)
mediator.health.wait_for_initialized()

val sequencerConnection = SequencerConnection.tryReadFromFile("sequencer-connection.bin")
domain.setup.init(sequencerConnection)
domain.health.wait_for_initialized()

health.status
```

If these commands were successful then you will see a health status that lists the 'domain', 'sequencer', and 'mediator' values.  This means the domain has been initialized.  An example of the expected output is below.
```
@ health.status
res25: EnterpriseCantonStatus = Status for DomainManager 'domain':
Node uid: domain::12204cbfba056cb001160bfeb7f48d092030cdce6321469d630f69d1322c70703202
Uptime: 6m 16.572267s
Ports:
	admin: 4801
Active: true

Status for Sequencer 'sequencer':
Sequencer id: domain::12204cbfba056cb001160bfeb7f48d092030cdce6321469d630f69d1322c70703202
Domain id: domain::12204cbfba056cb001160bfeb7f48d092030cdce6321469d630f69d1322c70703202
Uptime: 6m 19.747205s
Ports:
	public: 4401
	admin: 4402
Connected Participants: None
Sequencer: SequencerHealthStatus(isActive = true)
details-extra: None

Status for Mediator 'mediator':
Node uid: domain::12204cbfba056cb001160bfeb7f48d092030cdce6321469d630f69d1322c70703202
Domain id: domain::12204cbfba056cb001160bfeb7f48d092030cdce6321469d630f69d1322c70703202
Uptime: 6m 17.676996s
Ports:
	admin: 4602
Active: true
```

## To Start Participants

A remote participant needs to receive:
- Certificate chain (root and intermediate) of Domain PKI CA
- URL to exposed Sequencer Public API

In this setup the domain auto-approves join of new Participants to domain. There are 
options to make this require an approval step of the Domain Operator 
([Permissioned Domains](https://docs.daml.com/canton/usermanual/identity_management.html#permissioned-domains)).

### Participant 1
```
./start-postgres-participant1.sh
./start-participant1.sh
```

The following done in bootstrap script (passed as a parameter in the Bash script)
```
val sequencerUrl = sys.env.get("SEQUENCER_URL").getOrElse("http://localhost:4401")
participant1.domains.connect("sequencer", sequencerUrl)
```

### Participant 2
```
./start-postgres-participant2.sh
./start-participant2.sh
```
Following done in bootstrap script
```
val sequencerUrl = sys.env.get("SEQUENCER_URL").getOrElse("http://localhost:4401")
participant2.domains.connect("sequencer", sequencerUrl)
```

At this point, you should have a domain and two participants initialized and connected. You 
can use the following commands in the Remote Admin and Participant Consoles to check
everything is working.

```angular2html
# check on health of domain and participants
health.status

# On Domain remote console to view all parties (only participants at this point)
domain.participants.list()
domain.parties.list()
```

Listing the participants will show information similar to that below.
```
@ domain.participants.list()
res27: Seq[ListParticipantDomainStateResult] = Vector(
  ListParticipantDomainStateResult(
    context = BaseResult(
      domain = "Authorized",
      validFrom = 2022-08-22T20:02:20.934734Z,
      validUntil = None,
      operation = Add,
      serialized = <ByteString@2d38cc6 size=552 contents="\n\245\004\n\323\001\n\320\001\n\315\001\022 MY2jxg3bMLuiSrO3DQv21aUEbWv00LroB...">,
      signedBy = 12204cbfba05...
    ),
    item = ParticipantState(From, domain::12204cbfba05..., PAR::participant1::1220ac84a861..., Submission, Ordinary)
  ),
  ListParticipantDomainStateResult(
    context = BaseResult(
      domain = "Authorized",
      validFrom = 2022-08-22T20:05:59.001312Z,
      validUntil = None,
      operation = Add,
      serialized = <ByteString@7acb0140 size=552 contents="\n\245\004\n\323\001\n\320\001\n\315\001\022 Hs5ZizBNycghz2mnLbIKNSNDk5LCkRsoB...">,
      signedBy = 12204cbfba05...
    ),
    item = ParticipantState(From, domain::12204cbfba05..., PAR::participant2::1220b23c25a6..., Submission, Ordinary)
  )
)
```

Congratulations! You have a Canton Domain up along with Participants. 

Next: [Local testing through Canton Console](./test-local.md)

**Copyright (c) 2022 Digital Asset (Switzerland) GmbH and/or its affiliates. All rights reserved.
SPDX-License-Identifier: Apache-2.0**

