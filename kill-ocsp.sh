#!/bin/bash

touch ocsp_kill_switch
killall -9 openssl
rm ocsp_kill_switch


