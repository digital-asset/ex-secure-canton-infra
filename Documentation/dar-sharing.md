# [Alpha] Sharing Dars across participant nodes through console commands

TODO: Needs to be made into a real example

```angular2html
# Canton Console Helper functions:

# Dump and load party via text strings
val aliceAsStr = alice.toProtoPrimitive
val aliceParsed = PartyId.tryFromProtoPrimitive(aliceAsStr)

# Dump and load participant via text strings
val p2UidString = participant2.id.uid.toProtoPrimitive
val p2FromUid = ParticipantId(UniqueIdentifier.tryFromProtoPrimitive(p2UidString))
```

```
# Following should be empty
participant1.ledger_api.acs.of_party(participant1.adminParty)
participant2.ledger_api.acs.of_party(participant2.adminParty)

val cantonExamplesHash = participant1.dars.upload(CantonExamplesPath)

participant1.dars.sharing.requests.propose(cantonExamplesHash, participant2.id)

participant1.dars.sharing.requests.list().size

participant2.dars.sharing.offers.list().size


val offer = participant2.dars.sharing.offers.list().headOption.getOrElse(fail("archive offer disappeared"))
participant2.dars.sharing.offers.accept(offer.id)

participant2.dars.list().map(_.hash) should contain(offer.darHash)

participant2.dars.sharing.offers.list()

participant1.dars.sharing.requests.list()

val cantonExamplesHash =
participant1.dars.upload(CantonExamplesPath)


participant2.dars.sharing.whitelist.add(participant1.id.adminParty)

participant1.dars.sharing.requests.propose(cantonExamplesHash, participant2.id)

participant2.dars.list().map(_.hash) 


```


**Copyright (c) 2024 Digital Asset (Switzerland) GmbH and/or its affiliates. All rights reserved.
SPDX-License-Identifier: Apache-2.0**

