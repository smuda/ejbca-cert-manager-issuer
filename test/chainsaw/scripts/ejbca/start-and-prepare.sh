#!/bin/bash

set -eux

SCRIPT_PATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
NAMESPACE=ejbca
INPUT_CSR_FILE=${SCRIPT_PATH}/admin-cert/admin.csr
INPUT_CERT_PROFILE=asdf
INPUT_END_ENTITY_PROFILE=asdf
INPUT_CA_NAME=asdf
INPUT_USERNAME=asdf

# Install ejbca in namespace ejbca with the service ejbca
kubectl get ns "${NAMESPACE}" || kubectl create ns "${NAMESPACE}"
kubectl -n ejbca apply -f "${SCRIPT_PATH}/manifests/install-ejbca.yaml"
# ejbca is a Java app and as such takes a long time to
# start and initialize. Just wait it out.
kubectl -n ejbca wait deployment \
	  ejbca \
	  --for condition=Available=True \
	  --timeout=180s

# Setup port-forward to the CA
kubectl -n "${NAMESPACE}" port-forward svc/ejbca 8443:443 > /dev/null 2>&1 &

pid=$!
# echo pid: $pid

# kill the port-forward regardless of how this script exits
trap '{
    # echo killing $pid
    kill $pid
}' EXIT

# wait for 8443 to become available
while ! nc -vz localhost 8443 > /dev/null 2>&1 ; do
    # echo sleeping
    sleep 0.1
done

# Fetch the server certificate for later use
SERVER_CERT=$(keytool -printcert -sslserver "localhost:8443" -rfc)

# Create crypto token. The EJBCA community edition cannot handle this via API
echo ""
echo "This will open the web browser. Manually create the crypto token 'e2e': with Authentication code: 'e2e'"
echo "Then create three keys with Keysize RSA 2048"
echo "- signKey"
echo "- encryptKey"
echo "- testKey"

echo "Press any key to continue"
read -n 1 -s
open "https://localhost:8443/ejbca/adminweb/cryptotoken/cryptotokens.xhtml"

read -n 1 -s
echo "Press any key to continue"

# Create Certificate profile for CA. The EJBCA community edition cannot handle this via API
echo ""
echo "This will open the web browser. By cloning the ROOTCA profile, create the profile E2ECA."
echo "Then edit the profile and de-select LDAP DN Order"

echo "Press any key to continue"
read -n 1 -s
open "https://localhost:8443/ejbca/adminweb/ca/editcertificateprofiles/editcertificateprofiles.xhtml"

echo "Press any key to continue"
read -n 1 -s

# Create Certificate profile for End Entity. The EJBCA community edition cannot handle this via API
echo ""
echo "This will open the web browser. By cloning the ENDUSER profile, create the profile 'TLS Server Profile'."
echo "Then edit the profile:"
echo "- de-select LDAP DN Order"
echo "Extended Key Usage: Server Authentication"

echo "Press any key to continue"
read -n 1 -s
open "https://localhost:8443/ejbca/adminweb/ca/editcertificateprofiles/editcertificateprofiles.xhtml"

echo "Press any key to continue"
read -n 1 -s

# Create the CA. The EJBCA community edition cannot handle this via API
echo ""
echo "This will open the web browser. Create a new CA with name E2ECA:"
echo "Crypto Token:       e2e"
echo "defaultKey:         encryptKey"
echo "certSignKey:        signKey"
echo "keyEncryptKey:      '- Default'"
echo "Certificate Profile: E2ECA"
echo "Validity:            10y"
echo "Deselect LDAP DN Order"

echo "Press any key to continue"
read -n 1 -s
open "https://localhost:8443/ejbca/adminweb/ca/editcas/managecas.xhtml"

echo "Press any key to continue"
read -n 1 -s

# Add role for cert-manager. The EJBCA community edition cannot handle this via API
echo ""
echo "This will open the web browser. Create a new Role with name 'RA-cert-manager'."
echo ""
echo "Edit role access rules and set the following:"
echo "Role Template: RA Administrators"
echo "Authorized CAs: E2ECA"
echo "End entity profiles: All"
echo ""
echo "Add members to the role"
echo "Match with: X509 CN"
echo "CA:         E2ECA"
echo "Value:      cert-manager-ra-01"

echo "Press any key to continue"
read -n 1 -s
open "https://localhost:8443/ejbca/adminweb/administratorprivileges/roles.xhtml"

echo "Press any key to continue"
read -n 1 -s

# Create end entity profile. The EJBCA community edition cannot handle this via API
echo ""
echo "This will open the web browser. Create a new End Entity Profile 'RA-administrator'."
echo "Edit the profile:"
echo "Default CA: E2ECA"

echo "Press any key to continue"
read -n 1 -s
open "https://localhost:8443/ejbca/adminweb/administratorprivileges/roles.xhtml"

echo "Press any key to continue"
read -n 1 -s



# Issue RA certificate. The EJBCA community edition cannot handle this via API
echo ""
echo "This will open the web browser. Create a new certificate with name 'RA-cert-manager'."
echo "Choose to create a new request:"
echo "Certificate type:    RA-administrator"
echo "Certificat subtype:  ENDUSER"
echo "CA:                  E2ECA"
echo "Key-pair generation: Provided by user"
echo "Username:            cert-manager-ra-01"
echo ""
echo "Select 'Download PEM full chain'"

cat "${SCRIPT_PATH}/admin-cert/admin.csr"

echo "Press any key to continue"
read -n 1 -s
open "https://localhost:8443/ejbca/ra/"

echo "Press any key to continue"
read -n 1 -s

echo "Copy the downloaded file to ${SCRIPT_PATH}/admin-cert/admin.pem"
read -n 1 -s

# Issue certificate from a pre-generated CSR
#csr="$(cat ${INPUT_CSR_FILE})"

# shellcheck disable=SC2016
#template='{"certificate_request":$csr, "certificate_profile_name":$cp, "end_entity_profile_name":$eep, "certificate_authority_name":$ca, "username":$ee, "password":$pwd}'
#json_payload=$(jq -n \
#    --arg csr "$csr" \
#    --arg cp "$INPUT_CERT_PROFILE" \
#    --arg eep "$INPUT_END_ENTITY_PROFILE" \
#    --arg ca "$INPUT_CA_NAME" \
#    --arg ee "$INPUT_USERNAME" \
#    --arg pwd "qwerty12345" \
#    "$template")

#RESPONSE=$(curl -X POST -s \
#    -H 'Content-Type: application/json' \
#    --data "$json_payload" \
#    --insecure \
#    "https://localhost:8443/ejbca/ejbca-rest-api/v1/certificate/pkcs10enroll")


    #| jq -r .certificate | base64 -d > "${INPUT_USERNAME}-der.crt"

#curl -X POST -s \
#    --cert-type P12 \
#    --cert "$INPUT_P12_CREDENTIAL:$INPUT_P12_CREDENTIAL_PASSWD" \
#    -H 'Content-Type: application/json' \
#    --data "$json_payload" \
#    "https://${INPUT_HOSTNAME}/ejbca/ejbca-rest-api/v1/certificate/pkcs10enroll" \
#    | jq -r .certificate | base64 -d > "${INPUT_USERNAME}-der.crt"
