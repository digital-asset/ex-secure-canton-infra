# Local Testing in each Daml Canton Console

In this step, we demonstrate:
- Creation of Parties through the Console
- Walk through the Canton Example steps. However we don't assume a single console with access to every node.

This sequence follows the example in [Getting Started](https://docs.daml.com/canton/tutorials/getting_started.html). 
This creates a few parties on participants 1 & 2 and then runs through creation of an Iou, a Paint offer, acceptance, etc.
Due to separate participants, the commands need to be executed on the correct participant console, in the same way a real deployment
will have separate operators for each participant.

Particular things to note:
- Unlike the Script example, the party Ids have the name of the party embedded in the Id. The Script equivalent creates
random Ids which means an out of band mechanism is required to allow everyone to understand which party Id represent which 
specific legal entity.
  - Note that creating enties with a prefix like "Alice" through the Console means that this name is shared across the Domain and may represent a privacy risk.
- Each participant node has separate actions. Do not assume a single Console with access 
to all participants.
- The variables "participant1" and "participant2" come from the respective start up configuration files. If you change the 
names in the config files then the variable that is exposed in the console changes.

NOTE: Assuming this executed correctly then we recommend that you **wipe and recreate** environment for
Script testing. It will not affect the later demos if you in place and will demonstrate the different
party id formats.


```
## On P1
participant1.id

# Setup Users
## On particpant 1 console
val alice = participant1.parties.enable("Alice")
# Load the dar file into the participant
val darPath=scala.util.Properties.envOrElse("CANTON_DIR", "./canton-enterprise-2.7.4") + "/dars/CantonExamples.dar"
participant1.dars.upload(darPath)

## On particpant 2 console
val bob = participant2.parties.enable("Bob")
val bank = participant2.parties.enable("Bank", waitForDomain = DomainChoice.All)
val darPath=scala.util.Properties.envOrElse("CANTON_DIR", "./canton-enterprise-2.7.4") + "/dars/CantonExamples.dar"
participant2.dars.upload(darPath)

## On P1
participant1.parties.list()
# Test connectivity between the two participants
var participant2 = participant1.parties.list("participant2")(0).participants(0).participant
participant1.health.ping(participant2)

##on P2
var participant1 = participant2.parties.list("participant1")(0).participants(0).participant
participant2.health.ping(participant1)

## on P2
val pkgIou = participant2.packages.find("Iou").head
var alice = participant2.parties.list("Alice")(0).party
var bank = participant2.parties.list("Bank")(0).party
val createIouCmd = ledger_api_utils.create(pkgIou.packageId,"Iou","Iou",Map("payer" -> bank,"owner" -> alice,"amount" -> Map("value" -> 100.0, "currency" -> "EUR"),"viewers" -> List()))
participant2.ledger_api.commands.submit(Seq(bank), Seq(createIouCmd))

## on P1
var alice = participant1.parties.list("Alice")(0).party
val aliceIou = participant1.ledger_api.acs.find_generic(alice, _.templateId == "Iou.Iou")
participant1.ledger_api.acs.of_party(alice)
participant1.ledger_api.acs.of_party(alice).map(x => (x.templateId, x.arguments))

## on P2
var alice = participant2.parties.list("Alice")(0).party
var bank = participant2.parties.list("Bank")(0).party
val pkgPaint = participant2.packages.find("Paint").head
val createOfferCmd = ledger_api_utils.create(pkgPaint.packageId, "Paint", "OfferToPaintHouseByPainter", Map("bank" -> bank, "houseOwner" -> alice, "painter" -> bob, "amount" -> Map("value" -> 100.0, "currency" -> "EUR")))
participant2.ledger_api.commands.submit_flat(Seq(bob), Seq(createOfferCmd))

## on P1
val paintOffer = participant1.ledger_api.acs.find_generic(alice, _.templateId == "Paint.OfferToPaintHouseByPainter")
participant1.ledger_api.acs.of_party(alice).map(x => (x.templateId, x.arguments))

## on P2
participant2.ledger_api.acs.of_party(bank).map(x => (x.templateId, x.arguments))

## on P1
import com.digitalasset.canton.protocol.LfContractId
val acceptOffer = ledger_api_utils.exercise("AcceptByOwner", Map("iouId" -> LfContractId.assertFromString(aliceIou.event.contractId)),paintOffer.event)
participant1.ledger_api.commands.submit_flat(Seq(alice), Seq(acceptOffer))

## on P2
participant2.ledger_api.acs.of_party(bank).map(x => (x.templateId, x.arguments))

```

Next: [Testing using Daml Script and REPL console](./test-script.md)


**Copyright (c) 2024 Digital Asset (Switzerland) GmbH and/or its affiliates. All rights reserved.
SPDX-License-Identifier: Apache-2.0**


