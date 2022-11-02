#!/bin/python3

from passlib.hash import pbkdf2_sha256
import json
import sys

input_file = sys.argv[1]
issuer_for = sys.argv[2]
participant_id = sys.argv[3]
party_mapping_file = sys.argv[4]
party_mapping = None

participant_data = {}
participant_data['participant_id'] = participant_id
participant_data['user_auth'] = []

with open(party_mapping_file,"r") as tmp_map:
   party_mapping = json.load(tmp_map)

#print(party_mapping)

with open(input_file, "r") as tmp_file:
   user_accounts = json.load(tmp_file)

   #print(user_accounts)

   for account in user_accounts:
      #print(account)
      if (account['participant_id'] == 'all' or account['participant_id'] == issuer_for):

         # Overwite secret with hashed version
         tmp_secret = account['client_secret']
         account['client_secret'] = pbkdf2_sha256.hash(tmp_secret)

         # Fix up participant_id
         if (account['participant_id'] == 'all'):
            account['participant_id'] = issuer_for

         tmp_parties = account['parties']
         account['parties'] = []
         for party in tmp_parties:
            account['parties'].append(party_mapping[party])

         participant_data['user_auth'].append(account)

configuration_data = {
   "client_id": "participant_admin",
   "client_secret": "AdminPassphrase!",
   "participant_data": participant_data
}

print(json.dumps(configuration_data))





