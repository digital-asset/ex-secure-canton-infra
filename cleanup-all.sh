#!/bin/bash
# Copyright (c) 2022 Digital Asset (Switzerland) GmbH and/or its affiliates. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

rm -rf certs
rm log/*
rm dars/*
rm data/*

docker stop lb-sequencer
docker rm lb-sequencer

docker stop lb-participant1
docker rm lb-participant1

docker stop lb-json-p1
docker rm lb-json-p1

docker stop lb-json-p2
docker rm lb-json-p2

docker stop domain-postgres
docker rm domain-postgres

docker stop participant1-postgres
docker rm participant1-postgres

docker stop participant2-postgres
docker rm participant2-postgres
