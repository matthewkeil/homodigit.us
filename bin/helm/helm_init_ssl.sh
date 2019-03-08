#!/bin/bash
# set -x

DIR=../tiller

[[ ! -d $DIR ]] && mkdir "$DIR"
#
#
#   Build csr
#
#
function makeKeyCsrCertSet() {
    [[ ! $1 ]] && return 1

    PREFIX=${DIR}/${1}
    
    if [[ ! -f ${PREFIX}.csr || ! -f ${PREFIX}.key ]]; then
        printf "\n>>>\n>>> creating key and csr pair for ${1}...\n>>>\n"
        openssl req -new -sha256 -nodes \
            -newkey rsa:4096 -keyout "$PREFIX".key \
            -out "$PREFIX".csr \
            -config <( cat ../ssl/homodigit.us.conf ) > /dev/null 2>&1
    else
        printf "\n>>>\n>>> ${1} key and csr both exist. skipping\n>>>\n"
    fi

    SIGNATORY="${DIR}/signing"
    
    [[ $1 == 'signing' ]] && SIGNATORY="${DIR}/ca"

    printf "\n>>>\n>>> $SIGNATORY cert signing for ${1}.crt\n>>>\n"

    openssl x509 -req -days 500 -sha256 \
        -in "$PREFIX".csr -out "$PREFIX".crt \
        -CA "$SIGNATORY".crt -CAkey "$SIGNATORY".key -CAcreateserial  \
        -extfile ../ssl/homodigit.us.X509.conf \
        -passin "pass:homodigitus" > /dev/null 2>&1
}
#
#
#   Build cert
#
#
function generateCACerts() {
    PREFIX=${DIR}/ca

    if [[ -f ${PREFIX}.key ]]; then
        printf "\n>>>\n>>> ca.key exists. skipping...\n>>>\n"
    else 
        printf "\n>>>\n>>> ca.key is missing. generating one\n>>>\n"
        openssl genrsa -out ${PREFIX}.key 4096 > /dev/null 2>&1
    fi
    
    if [[ -f ${PREFIX}.crt ]]; then
        printf "\n>>>\n>>> ca.crt exists. skipping...\n>>>\n"
    else 
        printf "\n>>>\n>>> ca.crt is missing. generating one\n>>>\n"
        CUR_DIR="$(pwd)"
        cd $DIR && rm $(ls | grep -e '.crt') > /dev/null 2>&1
        cd $CUR_DIR
        cat ../ssl/rootCA.conf | openssl req -key ${PREFIX}.key -new -x509 \
            -days 7300 -sha256 -out ${PREFIX}.crt -extensions v3_ca > /dev/null 2>&1
    fi
    
    makeKeyCsrCertSet signing
}
#
#
#   generate ca and signing certs
#
#
generateCACerts
#
#
#   generate account certs
#
#
makeKeyCsrCertSet tiller

cat "$DIR"/tiller.crt "$DIR"/signing.crt "$DIR"/ca.crt > "$DIR"/tiller.pem

makeKeyCsrCertSet helm

cat "$DIR"/helm.crt "$DIR"/signing.crt "$DIR"/ca.crt > "$DIR"/helm.pem

# [[ -f "$PREFIX".service-account.yaml ]] && printf "\n>>>\n>>> ${PREFIX}.service-account.yaml is missing\n>>>\n" && exit 1
# kubectl apply -f "$PREFIX".service-account.yaml

# [[ -f "$PREFIX".role-binding.yaml ]] && printf "\n>>>\n>>> ${PREFIX}.role-binding.yaml is missing\n>>>\n" && exit 1
# kubectl apply -f "$PREFIX".role-binding.yaml

# helm init --tiller-tls --tiller-tls-verify --tiller-tls-cert ssl/tiller.pem --tiller-tls-key ssl/tiller.key --tls-ca-cert ssl/ca.crt --service-account tiller