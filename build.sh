#!/bin/bash
# Copyright (c) 2024 Digital Asset (Switzerland) GmbH and/or its affiliates. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

# set -e

source env.sh

if [[ -z ${DAML_CMD} ]];then
    echo "DAML_CMD was not set.  Aborting."
    exit 1
fi
${DAML_CMD} damlc build --project-root . --output dars/SecureDaml.dar

# ignore me
