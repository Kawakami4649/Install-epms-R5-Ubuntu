#!/bin/bash

# 引数からドメイン名を取得
DOMAIN="$1"

# 引数がなければエラー
if [ -z "$DOMAIN" ]; then
    echo "❌ ドメイン名を指定してください。例: ./add_cron.sh chat.local"
    exit 1
fi

# CRONジョブの内容（半年ごとに証明書を更新）
CRON_JOB="0 3 1 */6 * /usr/local/bin/renew_cert.sh $DOMAIN"

# すでに登録されているか確認
crontab -l 2>/dev/null | grep -Fq "$CRON_JOB"

# 登録されていなければ追加
if [ $? -ne 0 ]; then
    (crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -
    echo "✅ CRONジョブを追加しました：$CRON_JOB"
else
    echo "ℹ️ CRONジョブはすでに登録されています。"
fi

