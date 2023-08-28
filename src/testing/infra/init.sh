#!/bin/sh

set -e -x

key_vault_cert="/home/locust/secrets/crt"
key_vault_secret="/home/locust/secrets/crt_secret"
dst="/home/locust/cert"

mkdir -p "$dst"
echo "-----BEGIN CERTIFICATE-----" | cat - "$key_vault_cert" > "$dst/locust.crt"
echo -n "\n-----END CERTIFICATE-----" >> "$dst/locust.crt"

openssl pkcs12 -in "$key_vault_secret" -passin pass: -out "$dst/locust.pem" -nodes -nocerts
