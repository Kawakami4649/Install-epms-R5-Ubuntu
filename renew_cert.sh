#!/bin/bash

DOMAIN="$1"
KEY_PATH="/etc/ssl/private/${DOMAIN}.key"
CRT_PATH="/etc/ssl/certs/${DOMAIN}.crt"

# 秘密鍵の再生成
openssl genrsa -out "$KEY_PATH" 2048

# CSRの作成
openssl req -new -key "$KEY_PATH" -subj "/CN=${DOMAIN}" -out /tmp/${DOMAIN}.csr

# 自己署名証明書の作成（180日）
openssl x509 -req -days 180 -in /tmp/${DOMAIN}.csr -signkey "$KEY_PATH" -out "$CRT_PATH"

# 後片付け
rm /tmp/${DOMAIN}.csr

