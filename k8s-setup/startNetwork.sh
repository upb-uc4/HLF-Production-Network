# Color definitions for better readability
CYAN=$(tput setaf 6)
NORMAL=$(tput sgr0)

# Function definitions
get_pods() {
    kubectl get pods -l app=$1 --field-selector status.phase=Running  --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}' | head -n 1
}

small_sep() {
    printf "%s" "${CYAN}"
    printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
    printf "%s" "${NORMAL}"
}

sep() {
    printf "%s" "${CYAN}"
    printf '%*s\n' "${COLUMN:-$(tput cols)}" '' | tr ' ' =
    printf "%s" "${NORMAL}"
}

command() {
  echo "${CYAN}$1${NORMAL}"
}

# Debug commands using -d flag
export DEBUG=""
if  [[ $1 = "-d" ]]; then
    command "Debug mode activated"
    export DEBUG="-d"
fi

# Set environment variables
source ./env.sh

# Start minikube
if minikube status | grep -q 'host: Stopped'; then
  command "Starting Network"
  minikube start
fi

sep
command "TLS CA"
sep

# Create deployment for tls root ca
if (($(kubectl get deployment -l app=ca-tls-root --ignore-not-found | wc -l) < 2)); then
  command "Creating TLS CA deployment"
  kubectl create -f tls-ca/tls-ca.yaml
else
  command "TLS CA deployment already exists"
fi



# Expose service for tls root ca
if (($(kubectl get service -l app=ca-tls-root --ignore-not-found | wc -l) < 2)); then
  command "Creating TLS CA service"
  kubectl create -f tls-ca/tls-ca-service.yaml
else
  command "TLS CA service already exists"
fi
CA_SERVER_HOST=$(minikube service ca-tls --url | cut -c 8-)
command "TLS CA service exposed on $CA_SERVER_HOST"
small_sep


# Wait until pod is ready
command "Waiting for pod"
kubectl wait --for=condition=ready pod -l app=ca-tls-root --timeout=60s
TLS_CA_NAME=$(get_pods "ca-tls-root")
command "Using pod $TLS_CA_NAME"
small_sep



# Copy TLS certificate into local tmp folder
command "Copy TLS certificate to local folder"
export FABRIC_CA_CLIENT_TLS_CERTFILES=tls-ca-cert.pem
export FABRIC_CA_CLIENT_HOME=$TMP_FOLDER/hyperledger/tls-ca/admin
mkdir -p $TMP_FOLDER
mkdir -p $FABRIC_CA_CLIENT_HOME
kubectl cp default/$TLS_CA_NAME:etc/hyperledger/fabric-ca-server/ca-cert.pem $TMP_FOLDER/ca-cert.pem
small_sep


# Query TLS CA server to enroll an admin identity
command "Use CA-client to enroll admin"
small_sep
cp $TMP_FOLDER/ca-cert.pem $FABRIC_CA_CLIENT_HOME/$FABRIC_CA_CLIENT_TLS_CERTFILES
./$CA_CLIENT enroll $DEBUG -u https://tls-ca-admin:tls-ca-adminpw@$CA_SERVER_HOST
small_sep

# Query TLS CA server to register other identities
command "Use CA-client to register identities"
small_sep
# The id.secret password ca be used to enroll the registered users lateron
./$CA_CLIENT register --id.name orderer1-uc4 --id.secret ordererPW --id.type orderer -u https://tls-ca-admin:tls-ca-adminpw@$CA_SERVER_HOST
small_sep
./$CA_CLIENT register --id.name peer1-uc4 --id.secret peerPW --id.type peer -u https://tls-ca-admin:tls-ca-adminpw@$CA_SERVER_HOST

sep
command "Orderer Org CA"
sep

# Create deployment for orderer org ca
if (($(kubectl get deployment -l app=rca-org0-root --ignore-not-found | wc -l) < 2)); then
  command "Creating Orderer Org CA deployment"
  kubectl create -f orderer-org-ca/orderer-org-ca.yaml
else
  command "Orderer Org CA deployment already exists"
fi



# Expose service for orderer org ca
if (($(kubectl get service -l app=rca-org0-root --ignore-not-found | wc -l) < 2)); then
  command "Creating Orderer Org CA service"
  kubectl create -f orderer-org-ca/orderer-org-ca-service.yaml
else
  command "Orderer Org CA service already exists"
fi
# lokale Variable?
CA_ORDERER_HOST=$(minikube service rca-org0 --url | cut -c 8-)
command "Orderer Org CA service exposed on $CA_ORDERER_HOST"
small_sep


# Wait until pod is ready
command "Waiting for pod"
kubectl wait --for=condition=ready pod -l app=rca-org0-root --timeout=60s
ORDERER_ORG_CA_NAME=$(get_pods "rca-org0-root")
command "Using pod $ORDERER_ORG_CA_NAME"
small_sep


# Enroll Orderer Org's CA Admin

export FABRIC_CA_CLIENT_TLS_CERTFILES=ca-cert.pem
export FABRIC_CA_CLIENT_HOME=$TMP_FOLDER/hyperledger/org0/ca/admin
mkdir -p $FABRIC_CA_CLIENT_HOME

# Query TLS CA server to enroll an admin identity
command "Use CA-client to enroll admin"
small_sep
cp $TMP_FOLDER/ca-cert.pem $FABRIC_CA_CLIENT_HOME/$FABRIC_CA_CLIENT_TLS_CERTFILES
./$CA_CLIENT enroll $DEBUG -u https://rca-org0-admin:rca-org0-adminpw@$CA_ORDERER_HOST
small_sep

# Query TLS CA server to register other identities
command "Use CA-client to register identities"
small_sep
# The id.secret password ca be used to enroll the registered users lateron
./$CA_CLIENT register $DEBUG --id.name orderer1-org0 --id.secret ordererpw --id.type orderer -u https://$CA_ORDERER_HOST
small_sep
./$CA_CLIENT register $DEBUG --id.name admin-org0 --id.secret org0adminpw --id.type admin --id.attrs "hf.Registrar.Roles=client,hf.Registrar.Attributes=*,hf.Revoker=true,hf.GenCRL=true,admin=true:ecert,abac.init=true:ecert" -u https://$CA_ORDERER_HOST

sep




command "Org1 CA"
sep

# Create deployment for org1 ca
if (($(kubectl get deployment -l app=rca-org1-root --ignore-not-found | wc -l) < 2)); then
  command "Creating Org1 CA deployment"
  kubectl create -f org1-ca/org1-ca.yaml
else
  command "Org1 CA deployment already exists"
fi



# Expose service for org1 ca
if (($(kubectl get service -l app=rca-org1-root --ignore-not-found | wc -l) < 2)); then
  command "Creating Org1 CA service"
  kubectl create -f org1-ca/org1-ca-service.yaml
else
  command "Org1 CA service already exists"
fi
CA_ORG1_HOST=$(minikube service rca-org1 --url | cut -c 8-)
command "Org1 CA service exposed on $CA_ORG1_HOST"
small_sep


# Wait until pod is ready
command "Waiting for pod"
kubectl wait --for=condition=ready pod -l app=rca-org1-root --timeout=60s
ORG1_CA_NAME=$(get_pods "rca-org1-root")
command "Using pod $ORG1_CA_NAME"
small_sep


# Enroll Org1's CA Admin

export FABRIC_CA_CLIENT_TLS_CERTFILES=ca-cert.pem
export FABRIC_CA_CLIENT_HOME=$TMP_FOLDER/hyperledger/org1/ca/admin
mkdir -p $FABRIC_CA_CLIENT_HOME

# Query TLS CA server to enroll an admin identity
command "Use CA-client to enroll admin"
small_sep
cp $TMP_FOLDER/ca-cert.pem $FABRIC_CA_CLIENT_HOME/$FABRIC_CA_CLIENT_TLS_CERTFILES
./$CA_CLIENT enroll $DEBUG -u https://rca-org1-admin:rca-org1-adminpw@$CA_ORG1_HOST
small_sep

# Query TLS CA server to register other identities
command "Use CA-client to register identities"
small_sep
# The id.secret password ca be used to enroll the registered users lateron
./$CA_CLIENT register $DEBUG --id.name peer1-org1 --id.secret peer1PW --id.type peer -u https://$CA_ORG1_HOST
small_sep
./$CA_CLIENT register $DEBUG --id.name peer2-org1 --id.secret peer2PW --id.type peer -u https://$CA_ORG1_HOST
small_sep
./$CA_CLIENT register $DEBUG --id.name admin-org1 --id.secret org1AdminPW --id.type user -u https://$CA_ORG1_HOST
small_sep
./$CA_CLIENT register $DEBUG --id.name user-org1 --id.secret org1UserPW --id.type user -u https://$CA_ORG1_HOST


sep




command "Org2 CA"
sep

# Create deployment for org2 ca
if (($(kubectl get deployment -l app=rca-org2-root --ignore-not-found | wc -l) < 2)); then
  command "Creating Org2 CA deployment"
  kubectl create -f org2-ca/org2-ca.yaml
else
  command "Org2 CA deployment already exists"
fi



# Expose service for org2 ca
if (($(kubectl get service -l app=rca-org2-root --ignore-not-found | wc -l) < 2)); then
  command "Creating Org2 CA service"
  kubectl create -f org2-ca/org2-ca-service.yaml
else
  command "Org2 CA service already exists"
fi
CA_ORG2_HOST=$(minikube service rca-org2 --url | cut -c 8-)
command "Org2 CA service exposed on $CA_ORG2_HOST"
small_sep


# Wait until pod is ready
command "Waiting for pod"
kubectl wait --for=condition=ready pod -l app=rca-org2-root --timeout=60s
ORG2_CA_NAME=$(get_pods "rca-org2-root")
command "Using pod $ORG2_CA_NAME"
small_sep


# Enroll Org2's CA Admin

export FABRIC_CA_CLIENT_TLS_CERTFILES=ca-cert.pem
export FABRIC_CA_CLIENT_HOME=$TMP_FOLDER/hyperledger/org2ca/admin
mkdir -p $FABRIC_CA_CLIENT_HOME

# Query TLS CA server to enroll an admin identity
command "Use CA-client to enroll admin"
small_sep
cp $TMP_FOLDER/ca-cert.pem $FABRIC_CA_CLIENT_HOME/$FABRIC_CA_CLIENT_TLS_CERTFILES
./$CA_CLIENT enroll $DEBUG -u https://rca-org2-admin:rca-org2-adminpw@$CA_ORG2_HOST
small_sep

# Query TLS CA server to register other identities
command "Use CA-client to register identities"
small_sep
# The id.secret password ca be used to enroll the registered users lateron
./$CA_CLIENT register $DEBUG --id.name peer1-org2 --id.secret peer1PW --id.type peer -u https://$CA_ORG2_HOST
small_sep
./$CA_CLIENT register $DEBUG --id.name peer2-org2 --id.secret peer2PW --id.type peer -u https://$CA_ORG2_HOST
small_sep
./$CA_CLIENT register $DEBUG --id.name admin-org2 --id.secret org2AdminPW --id.type user -u https://$CA_ORG2_HOST
small_sep
./$CA_CLIENT register $DEBUG --id.name user-org2 --id.secret org2UserPW --id.type user -u https://$CA_ORG2_HOST


sep


echo -e "Done. Execute \e[2mminikube dashboard\e[22m to open the dashboard or run \e[2m./deleteNetwork.sh\e[22m to shutdown and delete the network."
