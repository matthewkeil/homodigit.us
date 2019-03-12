#!/bin/bash
set -x

if [[ ! $1 ]]; then
    read -p 'enter a name for the CA: ' NAME
else
    NAME=$1
fi

[[ ! $NAME ]] && exit 1

DIR=../"$NAME"
PREFIX="${DIR}/${NAME}"

[[ ! -d $DIR ]] && mkdir "$DIR"

openssl req -new -sha256 -nodes -out ../../"${NAME}"/"${NAME}"-signingCA.csr -newkey rsa:2048 \
    -keyout ../../"${NAME}"/"${NAME}"-signingCA.key -config <( cat ../homodigit.us.conf ) 

openssl x509 -req -in ../../"${NAME}"/"${NAME}"-signingCA.csr -CA ../rootCA.crt -CAkey ../rootCA.key \
    -CAcreateserial -out ../../"${NAME}"/"${NAME}"CA.crt -days 365 -passin "pass:homodigitus" \
    -sha256 -extfile homodigit.us.X509.conf

cat ../../"${NAME}"/"${NAME}"CA.crt rootCA.crt >> ../../"${NAME}"/"${NAME}"-signingCA.crt

cat ../../"${NAME}"/"${NAME}"-signingCA.key ../../"${NAME}"/"${NAME}"-signingCA.crt > ../../"${NAME}"/"${NAME}"-signingCA.pem
