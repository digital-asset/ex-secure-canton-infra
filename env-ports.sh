#!/bin/bash
# Copyright (c) 2024 Digital Asset (Switzerland) GmbH and/or its affiliates. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

# Overrides for Node host and port values

# This allows you to configure the hostname and ports for services. It also prepares for use of a load balancer where the
# port stays the same for the load-balancer but the underlying nodes change (port conflicts on single host) 
# If you use something other thann localhost then the name needs to resolve correctly to the hosting instannce for the node.


export PARTICIPANT_1_HOST=localhost
export PARTICIPANT_1_PORT=10011

export PARTICIPANT_1B_HOST=localhost

export PARTICIPANT_2_HOST=localhost
export PARTICIPANT_2_PORT=10021

# This is set to allow for a load-balancer. 
export SEQUENCER_HOST=localhost
export SEQUENCER_PORT=4401
export SEQUENCER_1_HOST=localhost
export SEQUENCER_2_HOST=localhost
export MEDIATOR_1_HOST=localhost
export MEDIATOR_2_HOST=localhost
export DOMAINMANAGER_HOST=localhost

export HEALTHCHECK_1_PORT=8001
export HEALTHCHECK_1B_PORT=8002

# The following are only used for testing OCSP certificate revocation
export OCSP_DOMAIN_ROOT_PORT=2561
export OCSP_DOMAIN_INTERMEDIATE_PORT=2562
export OCSP_PARTICIPANT1_ROOT_PORT=2563
export OCSP_PARTICIPANT1_INTERMEDIATE_PORT=2564
exportOCSP_PARTICIPANT2_ROOT_PORT=2565
export OCSP_PARTICIPANT2_INTERMEDIATE_PORT=2566

# JSON Participant1
export JSON_API_1_HOST=localhost
export JSON_API_1_PORT=9000
export JSON_API_1A_HOST=localhost
export JSON_API_1B_HOST=localhost
export JSON_API_1A_PORT=9001
export JSON_API_1B_PORT=9002

# JSON Participant2
export JSON_API_2_HOST=localhost
export JSON_API_2_PORT=9010
export JSON_API_2A_HOST=localhost
export JSON_API_2B_HOST=localhost
export JSON_API_2A_PORT=9011
export JSON_API_2B_PORT=9012

export JWTISSUER_1_HOST=localhost
export JWTISSUER_2_HOST=localhost
export JWTISSUER_1_PORT=9500
export JWTISSUER_2_PORT=9501

if [[ "CLIENTSIDE" == "$ENABLE_HA" || "NONE" == "$ENABLE_HA" ]]; then

export CANTON_SEQUENCER_1_PUBLIC_PORT=4401
export CANTON_SEQUENCER_1_ADMIN_PORT=4402
export CANTON_SEQUENCER_2_PUBLIC_PORT=4421
export CANTON_SEQUENCER_2_ADMIN_PORT=4422

export CANTON_MEDIATOR_1_ADMIN_PORT=4602
export CANTON_MEDIATOR_2_ADMIN_PORT=4604

export CANTON_DOMAINMANAGER_ADMIN_PORT=4801

export CANTON_PARTICIPANT_1_LEDGER_PORT=10011
export CANTON_PARTICIPANT_1_ADMIN_PORT=10012
export CANTON_PARTICIPANT_1_HEALTH_PORT=8001

export CANTON_PARTICIPANT_1B_LEDGER_PORT=10015
export CANTON_PARTICIPANT_1B_ADMIN_PORT=10016
export CANTON_PARTICIPANT_1B_HEALTH_PORT=8002

export CANTON_PARTICIPANT_2_LEDGER_PORT=10021
export CANTON_PARTICIPANT_2_ADMIN_PORT=10022

elif [ "LOADBALANCER" == "$ENABLE_HA" ] ; then

export CANTON_SEQUENCER_1_PUBLIC_PORT=4411
export CANTON_SEQUENCER_1_ADMIN_PORT=4412
export CANTON_SEQUENCER_2_PUBLIC_PORT=4421
export CANTON_SEQUENCER_2_ADMIN_PORT=4422

export CANTON_MEDIATOR_1_ADMIN_PORT=4602
export CANTON_MEDIATOR_2_ADMIN_PORT=4604

export CANTON_DOMAINMANAGER_ADMIN_PORT=4801

export CANTON_PARTICIPANT_1_LEDGER_PORT=10013
export CANTON_PARTICIPANT_1_ADMIN_PORT=10014
export CANTON_PARTICIPANT_1_HEALTH_PORT=8001

export CANTON_PARTICIPANT_1B_LEDGER_PORT=10015
export CANTON_PARTICIPANT_1B_ADMIN_PORT=10016
export CANTON_PARTICIPANT_1B_HEALTH_PORT=8002

export CANTON_PARTICIPANT_2_LEDGER_PORT=10021
export CANTON_PARTICIPANT_2_ADMIN_PORT=10022

fi

