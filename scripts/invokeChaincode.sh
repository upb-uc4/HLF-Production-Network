peer chaincode invoke -o orderer-org0:7050 --tls --cafile /tmp/hyperledger/org1/peer1/tls-msp/tlscacerts/tls-172-17-0-2-30905.pem -C mychannel -n uc4-cc -
-peerAddresses peer1-org1:7051 --tlsRootCertFiles /tmp/hyperledger/org1/peer1/tls-msp/signcerts/cert.pem --peerAddresses peer1-org2:7051 --tlsRootCertFiles /tmp/hyperledger/org2/peer1
/tls-msp/signcerts/cert.pem -c '{"function":"initLedger","Args":[]}'