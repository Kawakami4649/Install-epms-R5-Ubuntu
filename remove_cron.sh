#!/bin/bash

# 引数からドメイン名を取得
DOMAIN="$1"

if [ -z "$DOMAIN" ]; then
    echo "❌ ドメイン名を指定してください。例: ./remove_cron.sh chat.local"
    exit 1
fi

# 削除対象のジョブ
TARGET_JOB="/usr/local/bin/renew_cert.sh $DOMAIN"

# 現在のcrontabを取得して、対象ジョブを除外
crontab -l 2>/dev/null | grep -vF "$TARGET_JOB" | crontab -

echo "🗑️ CRONジョブを削除しました（対象: $TARGET_JOB）"

