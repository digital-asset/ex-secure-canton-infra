; NOTE: This fils is for training purposes and bypasses some security protocol
; items.  They are commented out below.


CREATE USER domain ENCRYPTED PASSWORD 'DomainPassword!';
CREATE DATABASE domain;
GRANT ALL PRIVILEGES ON DATABASE domain TO domain;

CREATE USER mediator ENCRYPTED PASSWORD 'MediatorPassword!';
CREATE DATABASE mediator;
GRANT ALL PRIVILEGES ON DATABASE mediator TO mediator;

CREATE USER sequencer ENCRYPTED PASSWORD 'SequencerPassword!';
CREATE DATABASE sequencer;
GRANT ALL PRIVILEGES ON DATABASE sequencer TO sequencer;

CREATE USER participant1 ENCRYPTED PASSWORD 'Participant1Password!';
CREATE DATABASE participant1;
GRANT ALL PRIVILEGES ON DATABASE participant1 TO participant1;

CREATE USER participant2 ENCRYPTED PASSWORD 'Participant2Password!';
CREATE DATABASE participant2;
GRANT ALL PRIVILEGES ON DATABASE participant2 TO participant2;

CREATE USER ledger ENCRYPTED PASSWORD 'LedgerPassword!';
CREATE DATABASE ledger;
GRANT ALL PRIVILEGES ON DATABASE ledger TO ledger;

; REVOKE ALL ON SCHEMA public FROM public;

; added echo "hostssl all all all scram-sha-256 clientcert=verify-full" >  $PGDATA/pg_hba.conf
; skipping echo "hostnossl all postgres 0.0.0.0/0 reject" >> $PGDATA/pg_hba.conf