#!/bin/bash

mkdir new_root

# openssl genrsa -out new_root/newrootCA.key 2048

openssl req -key new_root/newrootCA.key -new -x509 -days 7300 -sha256 -out new_root/newrootCA.cert -extensions v3_ca

