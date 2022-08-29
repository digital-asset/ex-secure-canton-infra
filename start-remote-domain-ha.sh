#!/bin/bash
# Copyright (c) 2022 Digital Asset (Switzerland) GmbH and/or its affiliates. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

source env.sh

$CANTON_DIR/bin/canton --log-file-name log/remote-domain.log -c configs/domain/remote-domain-ha.conf 
