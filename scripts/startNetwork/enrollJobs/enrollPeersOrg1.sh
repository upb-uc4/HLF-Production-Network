#!/bin/bash

source "/tmp/hyperledger/scripts/util.sh"

set -e

export CA_ORG1_HOST=rca-org1.hlf:7054
export CA_TLS_HOST=tls-ca.hlf:7052


log "Enroll Peer1 at Org1-CA"

export FABRIC_CA_CLIENT_HOME=/tmp/hyperledger/org1/peer1
export FABRIC_CA_CLIENT_TLS_CERTFILES=/tmp/secrets/rca-org1/cert.pem
export FABRIC_CA_CLIENT_MSPDIR=msp
mkdir -p $FABRIC_CA_CLIENT_HOME/assets/ca

fabric-ca-client enroll -u https://peer1-org1:peer1PW@$CA_ORG1_HOST


log "Enroll Peer1 at TLS-CA"

export FABRIC_CA_CLIENT_HOME=/tmp/hyperledger/org1/peer1
export FABRIC_CA_CLIENT_TLS_CERTFILES=/tmp/secrets/tls-ca/cert.pem
export FABRIC_CA_CLIENT_MSPDIR=tls-msp
mkdir -p $FABRIC_CA_CLIENT_HOME/assets/tls-ca
#cp /tmp/hyperledger/org1/ca/ca-cert.pem $FABRIC_CA_CLIENT_HOME/assets/tls-ca/tls-ca-cert.pem

fabric-ca-client enroll -u https://peer1-org1:peer1PW@$CA_TLS_HOST --enrollment.profile tls --csr.hosts peer1-org1

mv /tmp/hyperledger/org1/peer1/tls-msp/keystore/*_sk /tmp/hyperledger/org1/peer1/tls-msp/keystore/key.pem


log "Enroll Peer2 at Org1-CA"

export FABRIC_CA_CLIENT_HOME=/tmp/hyperledger/org1/peer2
export FABRIC_CA_CLIENT_TLS_CERTFILES=/tmp/secrets/rca-org1/cert.pem
export FABRIC_CA_CLIENT_MSPDIR=msp
mkdir -p $FABRIC_CA_CLIENT_HOME/assets/ca

fabric-ca-client enroll -u https://peer2-org1:peer2PW@$CA_ORG1_HOST


log "Enroll Peer2 at TLS-CA"

export FABRIC_CA_CLIENT_TLS_CERTFILES=/tmp/secrets/tls-ca/cert.pem
export FABRIC_CA_CLIENT_MSPDIR=tls-msp
mkdir -p $FABRIC_CA_CLIENT_HOME/assets/tls-ca
#cp /tmp/hyperledger/org1/ca/ca-cert.pem $FABRIC_CA_CLIENT_HOME/assets/tls-ca/tls-ca-cert.pem

fabric-ca-client enroll -u https://peer2-org1:peer2PW@$CA_TLS_HOST --enrollment.profile tls --csr.hosts peer2-org1

mv /tmp/hyperledger/org1/peer2/tls-msp/keystore/*_sk /tmp/hyperledger/org1/peer2/tls-msp/keystore/key.pem

echo "Enroll org1 admin identity"
export FABRIC_CA_CLIENT_HOME=/tmp/hyperledger/org1/admin
export FABRIC_CA_CLIENT_TLS_CERTFILES=/tmp/secrets/rca-org1/cert.pem
export FABRIC_CA_CLIENT_MSPDIR=msp
fabric-ca-client enroll -u https://admin-org1:org1AdminPW@$CA_ORG1_HOST


log "Distribute admin certificate across peers"

mkdir /tmp/hyperledger/org1/peer1/msp/admincerts
cp /tmp/hyperledger/org1/admin/msp/signcerts/cert.pem /tmp/hyperledger/org1/peer1/msp/admincerts/org1-admin-cert.pem
# usually this would happen out-of-band
mkdir /tmp/hyperledger/org1/peer2/msp/admincerts
cp /tmp/hyperledger/org1/admin/msp/signcerts/cert.pem /tmp/hyperledger/org1/peer2/msp/admincerts/org1-admin-cert.pem

