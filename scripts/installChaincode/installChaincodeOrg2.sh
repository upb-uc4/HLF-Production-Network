export CORE_PEER_ADDRESS=grpcs://peer1-org2.hlf:7051
export CORE_PEER_MSPCONFIGPATH=/tmp/hyperledger/org2/admin/msp
peer lifecycle chaincode install uc4-cc.tar.gz

export CORE_PEER_ADDRESS=grpcs://peer2-org2.hlf:7051
export CORE_PEER_MSPCONFIGPATH=/tmp/hyperledger/org2/admin/msp
peer lifecycle chaincode install uc4-cc.tar.gz
