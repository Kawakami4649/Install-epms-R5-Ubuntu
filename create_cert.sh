#!/bin/bash

# 任意のドメイン名を引数で受け取る
DOMAIN=$1

# ディレクトリの準備
KEY_DIR="/etc/ssl/private"
CRT_DIR="/etc/ssl/certs"
mkdir -p "$KEY_DIR" "$CRT_DIR"

# ファイル名
KEY_FILE="${KEY_DIR}/${DOMAIN}.key"
CRT_FILE="${CRT_DIR}/${DOMAIN}.crt"

# 秘密鍵の作成
openssl genrsa -out "$KEY_FILE" 2048

# CSRの作成（Common Nameにドメイン名を指定）
openssl req -new -key "$KEY_FILE" -subj "/CN=${DOMAIN}" -out /tmp/${DOMAIN}.csr

# 自己署名証明書の作成（180日有効）
openssl x509 -req -days 180 -in /tmp/${DOMAIN}.csr -signkey "$KEY_FILE" -out "$CRT_FILE"

# 後片付け
rm /tmp/${DOMAIN}.csr

echo "$CRT_FILE"
echo "$KEY_FILE"

