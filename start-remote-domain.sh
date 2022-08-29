#!/bin/bash
# Copyright (c) 2022 Digital Asset (Switzerland) GmbH and/or its affiliates. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

source env.sh

export POSTGRES_USER=domain
export POSTGRES_PASSWORD=DomainPassword!
# export POSTGRES_HOST=localhost
# export POSTGRES_PORT=5432
export POSTGRES_MAX_CONNECTIONS=8

$CANTON_DIR/bin/canton --log-file-name log/remote-domain.log -c configs/domain/remote-domain.conf
