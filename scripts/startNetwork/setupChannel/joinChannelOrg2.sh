export CORE_PEER_MSPCONFIGPATH=/tmp/hyperledger/org2/admin/msp
export CORE_PEER_ADDRESS=grpcs://peer1-org2.hlf:7051
peer channel join -b /tmp/hyperledger/shared/channel/mychannel.block

export CORE_PEER_ADDRESS=grpcs://peer2-org2.hlf:7051
peer channel join -b /tmp/hyperledger/shared/channel/mychannel.block