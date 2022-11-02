# Setup
- Remote consoles for participants - DONE
- Understanding operational actions around DAR upload / distribution
# Daml example
- Sample Daml App - Use CantonExamples to start - DONE
- Triggers talking to participants - DONE
# TLS
- Enable TLS on Sequencer, Mediator, Domain-Manager - DONE
- Enable mTLS on Admin API on Sequencer - DONE
- Enable TLS and JWT on Ledger API on participants - DONE
- Use party specific mTLS for authentication instead of admin cert
- Enable Postgres TLS for Domain and Participants - DONE
# JWT
- Enable JWT on Ledger API on participants - DONE
# Identity Management
- Understand user, party management on node - DONE
- Understand user/party management in Navigator - DONE (though User tokens are broken)
# Operational Actions
- Investigate how Parties are exposed across nodes - DONE
- Investigate JWT mapping to Parties and Users - DONE
  - Use of --application-id and User name - DONE
- Investigate UserRights, particularly Participant Admin right - DONE
- Investigate DAR upload and acceptance across participant nodes
# Backup / Restore
- Document backup of namespace root keys and delegation of namespace rights
# Navigator
- Test secure Navigator connections, JWT and Users - Done (though user based is broken)

