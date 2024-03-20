#!/bin/bash
# Copyright (c) 2024 Digital Asset (Switzerland) GmbH and/or its affiliates. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

source env.sh

export PARTICIPANT_TOKEN=`cat certs/participant1/jwt/participant_admin.token`

./$CANTON_DIR/bin/canton --log-file-name log/remote-participant1.log -c configs/participant/remote-participant-1-ha.conf 
