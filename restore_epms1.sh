#!/bin/bash

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

MOUNT_POINT="/media/pi"

echo -e "${GREEN}🔍 外部メディアをスキャン中...${NC}"

# /dev/sdX や /dev/mmcblkX を対象にスキャン（/dev/sda は除外）
DEVICES=$(lsblk -dpno NAME,TYPE | grep "disk" | grep -v "/dev/sda" | awk '{print $1}')

if [ -z "$DEVICES" ]; then
    echo -e "${RED}❌ 外部メディアが見つかりません。接続してください。${NC}"
    exit 1
fi

echo "✅ 検出されたデバイス："
echo "$DEVICES"
echo ""

echo "🧭 リストア元のデバイスを選んでください："
select DEV in $DEVICES; do
    if [ -n "$DEV" ]; then
        echo "選択されたデバイス: $DEV"
        break
    else
        echo "無効な選択です。"
    fi
done

# パーティション取得（例：/dev/sdb1）
#PART=$(lsblk -lnpo NAME "$DEV" | grep -v "$DEV" | head -n 1)
# パーティション取得（mmcblk0p1 や sdb1 に対応）
PART=""
for i in {1..5}; do
    PART=$(lsblk -lnpo NAME "$DEV" | grep -E "^$DEV(p[0-9]+|[0-9]+)$" | head -n 1)
    if [ -n "$PART" ]; then
        break
    fi
    sleep 1
done

if [ -z "$PART" ]; then
    echo -e "${RED}❌ パーティションが見つかりません。${NC}"
    exit 1
fi

[ -z "$PART" ] && PART="$DEV"

# 既にマウントされていればアンマウント
if mount | grep -q "$MOUNT_POINT"; then
    echo "🔌 既存のマウントを解除中..."
    sudo umount "$MOUNT_POINT"
fi

# マウントポイント作成
sudo mkdir -p "$MOUNT_POINT"

echo "🔗 マウント中: $PART → $MOUNT_POINT"
sudo mount "$PART" "$MOUNT_POINT"

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ マウントに失敗しました。${NC}"
    exit 1
fi

# 最新のバックアップフォルダを取得
LATEST_BACKUP=$(ls -td "$MOUNT_POINT"/backup_* 2>/dev/null | head -n 1)

if [ -z "$LATEST_BACKUP" ]; then
    echo -e "${RED}❌ バックアップフォルダが見つかりません。${NC}"
    sudo umount "$MOUNT_POINT"
    exit 1
fi

echo -e "${GREEN}🔄 最新のバックアップを復元します: $LATEST_BACKUP${NC}"

# リストア対象と復元先の対応
declare -A RESTORE_MAP
RESTORE_MAP["usr_local_mta_bin"]="/usr/local/mta/bin"
RESTORE_MAP["var_spool_epms"]="/var/spool/epms"

RSYNC_OPTS="-avh --delete"

for DIR in "${!RESTORE_MAP[@]}"; do
    SRC="$LATEST_BACKUP/$DIR/"
    DEST="${RESTORE_MAP[$DIR]}"

    if [ -d "$SRC" ]; then
        echo "📂 復元中: $SRC → $DEST"
        sudo rsync $RSYNC_OPTS "$SRC" "$DEST"
    else
        echo -e "${RED}⚠️ バックアップ元が見つかりません: $SRC${NC}"
    fi
done

echo -e "${GREEN}✅ リストア完了！${NC}"

# アンマウント処理
echo "🔌 メディアをアンマウント中..."
sudo umount "$MOUNT_POINT"

echo -e "${GREEN}📤 メディアを安全に取り外せます。${NC}"

