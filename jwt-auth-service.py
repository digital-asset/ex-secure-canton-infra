#!/usr/local/bin/python
# Copyright (c) 2024 Digital Asset (Switzerland) GmbH and/or its affiliates. All rights reserved.
# SPDX-License-Identifier: Apache-2.0
import os.path
# Based on example from Github GIST: https://gist.github.com/ktmud/a63778d9d0d37d030d72e6ca0b9ac356

from http.server import ThreadingHTTPServer, BaseHTTPRequestHandler
import threading
import time
from threading import Thread
from typing import Set

from watchdog.observers import Observer
from watchdog.events import PatternMatchingEventHandler

import ssl
import time
import logging
import sys
import urllib.parse
import json
import base64
from jwcrypto import jwk,jwt
from passlib.hash import pbkdf2_sha256

logger = None

# Signing Key
signing_key_file = None
signing_kid_file = None
signing_ca_file = None

# HTTPS TLS Keys
tls_key_file = None
tls_cert_file = None

# KeySet File
keyset_json = None
keyset: "jwcrypto.jwk.JWKSet" = None

service_configured = False
listen_port = 4443
default_auth_file = None
user_auth_file = None
participant_id = None
issuer_for = None


class JWTHTTPRequestHandler(BaseHTTPRequestHandler):

    def load_jwks(self):
        global keyset
        global keyset_json
        global service_configured

        key : "jwcrypto.jwk.JWK"
        with open(signing_cert_file, "r") as pemfile:
            key = jwk.JWK.from_pem(pemfile.read().encode('UTF-8'))

        keyset = jwk.JWKSet()
        keyset.add(key)
        keyset_json = json.loads(keyset.export(private_keys=False))
        #logger.debug(keyset_json)

        if (os.path.exists(user_auth_file)):
            service_configured = True

    def do_GET(self):
        global keyset
        global keyset_json

        if (self.path == "/.well_known/jwks.json"):
            self.load_jwks()

            self.send_response(200)
            self.end_headers()
            self.wfile.write(keyset.export(private_keys=False).encode('UTF-8'))

        else:
            self.send_response(500)
            self.end_headers()
            self.wfile.write(b'Invalid GET request')

    def do_POST(self):

        global signing_key_file
        global signing_kid_file
        global participant_id
        global logger
        global keyset
        global keyset_json
        global issuer_for
        global service_configured

        self.load_jwks()

        client_id = None
        audience = None

        if (self.path == "/auth"):
            if self.headers.get('Content-Length', None) == None:
                self.send_response(400)
                self.end_headers()
                self.wfile.write(b'No credential data sent')
                return

            content_length = int(self.headers['Content-Length'])
            body = self.rfile.read(content_length)

            if (service_configured == False):
                logger.error("Error: service not configured yet")
                self.send_response(500)
                self.end_headers()
                self.wfile.write(b'Error - auth service not configured yet')
                return

            body_json = None
            if self.headers['Content-Type'] == 'application/x-www-form-urlencoded':
                try:
                    body_json = urllib.parse.parse_qs(body.decode('UTF-8'))
                    client_id = body_json['client_id'][0]
                    client_secret = body_json['client_secret'][0]
                    grant_type = body_json['grant_type'][0]
                    audience = body_json['audience'][0]

                except Exception as ex:
                    logger.error("Error: {}".format(ex))
                    self.send_response(500)
                    self.end_headers()
                    self.wfile.write(b'Error processing request')
                    return

            if self.headers['Content-Type'] == 'application/json':
                try:
                    body_json = json.loads(body)
                    #logger.error(body_json)
                    client_id = body_json['client_id']
                    client_secret = body_json['client_secret']
                    grant_type = body_json['grant_type']
                    audience = body_json['audience']
                except Exception as ex:
                    logger.error("Error: {}".format(ex))
                    self.send_response(500)
                    self.end_headers()
                    self.wfile.write(b'Error processing request')
                    return

            if grant_type != 'client_credentials':
                logger.error("Invalid grant_type")
                self.send_response(400)
                self.end_headers()
                self.wfile.write(b'Invalid grant_type requested')
                return

            #if audience != "https://daml.com/ledger-api":
            #    logger.error("Invalid audience")
            #    self.send_response(400)
            #    self.end_headers()
            #    self.wfile.write(b'Invalid audience requested')
            #    return

            with open(user_auth_file, "r") as tmpfile:
                user_auth = json.load(tmpfile)
                tmpfile.close()

            logger.debug(user_auth)

            for client in user_auth:
                #logger.debug(client)
                if (client['client_id'] == client_id):
                    current_client = client

            if current_client == None:
                logger.error("Invalid credentials")
                self.send_response(400)
                self.end_headers()
                self.wfile.write(b'Invalid credentials provided')
                return

            # ***** NOT FOR PRODUCTION USE *****
            # Check user-auth file for which participant the user is expected on vs current issuer
            # Hacky way to limit JWT issuance for certain user to certain participants
            # participant_admin on all and this means common logon for all participants
            expected_participant = current_client.get('participant_id', None)
            logger.debug("Expected participant: {}".format(expected_participant))
            logger.debug("Issuer For: {}".format(issuer_for))
            if (expected_participant == None or (expected_participant != "all" and expected_participant != issuer_for)):
                logger.error("Invalid credentials")
                self.send_response(400)
                self.end_headers()
                self.wfile.write(b'Invalid credentials provided')
                return

            if pbkdf2_sha256.verify(client_secret, current_client['client_secret']) != True:
                logger.error("Invalid credentials")
                self.send_response(400)
                self.end_headers()
                self.wfile.write(b'Invalid credentials provided')
                return

            signing_key : "jwcrypto.jwk.JWK"
            with open(signing_key_file, "r") as pemfile:
                signing_key = jwk.JWK.from_pem(pemfile.read().encode('UTF-8'))

            issue_at = int(time.time())
            expiry_time = int(issue_at + 24*60*60)
            #logger.debug("Issued At: " + str(issue_at))
            #logger.debug("Expires At: " + str(expiry_time))

            #logger.debug(keyset_json)
            header = {"alg":"RS256","typ":"JWT", "kid": "" }
            header['kid'] = keyset_json['keys'][0]['kid']

            if (current_client['token_type'] == "user"):
                payload = {
                    "exp": expiry_time,
                    "scope": "daml_ledger_api",
                    "iss": "local-jwt-provider",
                    "iat": issue_at,
                    "sub": current_client['sub']
                }
                if (participant_id != None ):
                    payload["aud"] = participant_id

            elif current_client['token_type'] == "custom":
                payload = {
                    "https://daml.com/ledger-api": {
                        "ledgerId": participant_id,
                        "actAs": current_client['parties'],
                        "readAs": current_client['parties'],
                        "admin": current_client['admin'] == "True"
                    },
                    "exp": expiry_time,
                    "aud": "https://daml.com/ledger-api",
                    "azp": current_client['sub'],
                    "iss": "local-jwt-provider",
                    "iat": issue_at,
                    "gty": "client-credentials"
                }
            else:
                logger.error("Invalid token_type defined")
                self.send_response(500)
                self.end_headers()
                self.wfile.write(b'Internal error')
                return

            token = jwt.JWT(header=header, claims=payload)
            token.make_signed_token(signing_key)

            response_token = {
                "access_token": token.serialize(),
                "token_type": "Bearer",
                "expires_at": expiry_time
            }
            response_string = json.dumps(response_token)

            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()

            self.wfile.write(response_string.encode('UTF-8'))
        elif (self.path == "/configure"):

            logger.debug("Configuring")
            if self.headers.get('Content-Length', None) == None:
                self.send_response(400)
                self.end_headers()
                self.wfile.write(b'No credential data sent')
                return

            content_length = int(self.headers['Content-Length'])
            body = self.rfile.read(content_length)
            #logger.debug("Body: {}".format(body))

            if (service_configured == True):
                logger.error("Attempt to reconfigure")
                self.send_response(500)
                self.end_headers()
                self.wfile.write(b'Service already configured')
                return

            body_json = None
            tmp_participant_id = None
            if self.headers['Content-Type'] == 'application/json':
                try:
                    body_json = json.loads(body)
                    client_id = body_json['client_id']
                    client_secret = body_json['client_secret']
                    tmp_participant_data = body_json['participant_data']
                except Exception as ex:
                    logger.error("Error: {}".format(ex))
                    self.send_response(500)
                    self.end_headers()
                    self.wfile.write(b'Error processing request 2')
                    return

            if (client_id != "participant_admin"):
                logger.error("Error: {}".format(ex))
                self.send_response(500)
                self.end_headers()
                self.wfile.write(b'Invalid credentials')
                return

            with open(default_auth_file, "r") as tmpfile:
                user_auth = json.load(tmpfile)
                tmpfile.close()

            current_client = None
            #logger.debug(user_auth)
            for client in user_auth:
                #logger.debug(client)
                if (client['client_id'] == client_id):
                    current_client = client

            if current_client == None:
                logger.error("Invalid credentials")
                self.send_response(400)
                self.end_headers()
                self.wfile.write(b'Invalid credentials provided')
                return

            if pbkdf2_sha256.verify(client_secret, current_client['client_secret']) != True:
                logger.error("Invalid credentials")
                self.send_response(400)
                self.end_headers()
                self.wfile.write(b'Invalid credentials provided')
                return

            if tmp_participant_data != None:
                participant_data = tmp_participant_data

            participant_id = participant_data.get('participant_id', None)
            user_auth = participant_data.get('user_auth', None)

            logger.debug("participant_id set to {}".format(participant_data['participant_id']))
            logger.debug("user_auth set to {}".format(participant_data['user_auth']))

            if (participant_id == None or user_auth == None):
                logger.error("Invalid configuration data provided")
                self.send_response(500)
                self.end_headers()
                self.wfile.write(b'Invalid configuration provided')
                return

            with open(user_auth_file, "w") as tmpfile:
                json.dump(user_auth, tmpfile)
                tmpfile.close()

            service_configured = True

            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            self.wfile.write(b'Configuration Updated')
        else:
            logger.debug("Unknown path")
            self.send_response(500)
            self.end_headers()
            self.wfile.write(b'Internal error')

class JWTHttpServer(ThreadingHTTPServer):
    def __init__(self, port=int(listen_port)):
        super().__init__(("localhost", port), JWTHTTPRequestHandler)

    def start(self):
        logger.info(f"🚀 JWT service started at http://localhost:{self.server_port}")
        self.serve_forever()

    def stop(self):
        self.shutdown()
        self.server_close()

class AutoreloadHandler(PatternMatchingEventHandler):
    """Auto reload handlers"""

    def __init__(
            self,
            server: JWTHttpServer,
            patterns=None,
            ignore_patterns=None,
            ignore_directories=False,
            case_sensitive=False,
    ):
        super().__init__(patterns, ignore_patterns, ignore_directories, case_sensitive)
        self.server = server
        self.needs_reload: Set[str] = set()  # modules that need to be reloaded

        # mark last update to make sure we only reload 1s after the last update

        self.last_updated_at = time.time()
        # start another thread to check if we need to reload
        threading.Thread(target=lambda: self.check_reload()).start()

    def check_reload(self):
        while True:
            if self.needs_reload and time.time() - self.last_updated_at > 1:
                logger.debug("Change detected, restarting JWT service...\n")
                self.needs_reload.clear()
                self.server.stop()
                new_server = start_server_thread(self.server.server_port)
                if new_server:
                    self.server = new_server
            time.sleep(1)

    def on_any_event(self, event):
        #logger.debug("DEBUG: Path: {}".format(event.src_path))
        self.needs_reload.add(event.src_path)
        self.last_updated_at = time.time()

def init_logger():
    logger = logging.getLogger()

    h = logging.StreamHandler(sys.stdout)
    h.flush = sys.stdout.flush
    logger.addHandler(h)

    return logger

def start_server_thread(port: int):
    context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
    context.load_cert_chain(tls_cert_file, tls_key_file)

    server = JWTHttpServer(port)
    server.socket = context.wrap_socket(server.socket, server_side=True)

    server_thread = Thread(target=lambda: server.start())
    server_thread.start()
    return server

def start_jwt_service(autoreload=True):

    server = start_server_thread(int(listen_port))
    observer = None

    if autoreload:
        # start autoreload watcher in another thread
        observer = Observer()
        observer.schedule(
            AutoreloadHandler(
                server=server,
                patterns=[signing_key_file,
                          signing_cert_file,
                          signing_ca_file,
                          tls_key_file,
                          tls_cert_file
                          ],
                ignore_patterns=[],
            ),
            # monitor all "of.xxx" files
            os.path.commonpath([signing_key_file,
                                signing_cert_file,
                                signing_ca_file,
                                tls_key_file,
                                tls_cert_file
                                ]),
            recursive=True
        )
        observer.start()
        observer.on_thread_stop = lambda: server.stop()

    return observer

def main():

    global logger
    global issuer_for

    logger = init_logger()
    logger.setLevel(logging.DEBUG)

    logging.info("Starting Auth Service...")
    logging.info("Issuer For: {}".format(issuer_for))

    autoreload_observer = start_jwt_service()
    if autoreload_observer:
        try:
            autoreload_observer.join()
        except KeyboardInterrupt:
            autoreload_observer.stop()
            pass


if __name__ == '__main__':

    signing_key_file = sys.argv[1]
    signing_cert_file = sys.argv[2]
    signing_ca_file = sys.argv[3]
    tls_key_file = sys.argv[4]
    tls_cert_file = sys.argv[5]
    default_auth_file = sys.argv[6]
    listen_port = int(sys.argv[7])
    issuer_for = sys.argv[8]
    user_auth_file = sys.argv[9]

    main()
