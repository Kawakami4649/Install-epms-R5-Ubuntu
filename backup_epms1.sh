#!/bin/bash

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

SOURCE_DIRS=(
  "/usr/local/mta/bin"
  "/var/spool/epms"
)

MOUNT_POINT="/media/pi"
DATE=$(date +%Y-%m-%d_%H-%M)
BACKUP_FOLDER="backup_$DATE"
RSYNC_OPTS="-avh --delete"

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

echo "🧭 バックアップ先のデバイスを選んでください："
select DEV in $DEVICES; do
    if [ -n "$DEV" ]; then
        echo "選択されたデバイス: $DEV"
        break
    else
        echo "無効な選択です。"
    fi
done

# パーティション取得（例：/dev/sdb1）
PART=$(lsblk -lnpo NAME "$DEV" | grep -E "^$DEV[p0-9]+" | head -n 1)

# パーティションがなければ作成してフォーマット
if [ -z "$PART" ]; then
    echo -e "${GREEN}🛠️ パーティションが存在しません。作成してフォーマットします。${NC}"
    echo -e "${RED}⚠️ すべてのデータが削除されます。続行しますか？（yes/no）${NC}"
    read CONFIRM
    if [ "$CONFIRM" != "yes" ]; then
        echo "⛔ 中止しました。"
        exit 0
    fi

    echo "🧹 既存の署名を消去中..."
    sudo wipefs -a "$DEV"

    echo "🔧 パーティション作成中..."
    echo -e "o\nn\np\n1\n\n\nw" | sudo fdisk "$DEV"

    echo "🔄 パーティション情報を再読み込み中..."
    sudo partprobe "$DEV"
    sleep 2
fi

# パーティション再取得（mmcblk0p1対応）
for i in {1..5}; do
    PART=$(lsblk -lnpo NAME "$DEV" | grep -E "^$DEV(p[0-9]+|[0-9]+)$" | head -n 1)
    if [ -n "$PART" ]; then
        break
    fi
    sleep 1
done

if [ -z "$PART" ]; then
    echo -e "${RED}❌ パーティションの検出に失敗しました。${NC}"
    exit 1
fi

echo "💽 フォーマット中（ext4）..."
sudo mkfs.ext4 -F -L backup "$PART"

# マウント処理
if mount | grep -q "$MOUNT_POINT"; then
    echo "🔌 既存のマウントを解除中..."
    sudo umount "$MOUNT_POINT"
fi

sudo mkdir -p "$MOUNT_POINT"
echo "🔗 マウント中: $PART → $MOUNT_POINT"
sudo mount "$PART" "$MOUNT_POINT"

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ マウントに失敗しました。${NC}"
    exit 1
fi

DEST="$MOUNT_POINT/$BACKUP_FOLDER"
echo "📁 バックアップ先: $DEST"

# バックアップ元の合計サイズを計算
echo "📏 バックアップ元のサイズを計算中..."
TOTAL_SIZE=0
for SRC in "${SOURCE_DIRS[@]}"; do
    if [ -d "$SRC" ]; then
        SIZE=$(du -sb "$SRC" | awk '{print $1}')
        TOTAL_SIZE=$((TOTAL_SIZE + SIZE))
    fi
done

AVAILABLE_SPACE=$(df --output=avail -B1 "$MOUNT_POINT" | tail -1)

echo "📦 バックアップに必要な容量: $TOTAL_SIZE バイト"
echo "💽 バックアップ先の空き容量: $AVAILABLE_SPACE バイト"

if [ "$AVAILABLE_SPACE" -lt "$TOTAL_SIZE" ]; then
    echo -e "${RED}❌ 空き容量が不足しています。処理を中止します。${NC}"
    sudo umount "$MOUNT_POINT"
    exit 1
fi

# バックアップ実行
sudo mkdir -p "$DEST"
for SRC in "${SOURCE_DIRS[@]}"; do
    if [ -d "$SRC" ]; then
        BASENAME=$(echo "$SRC" | sed 's|/|_|g' | sed 's|^_||')
        echo "📂 バックアップ中: $SRC → $DEST/$BASENAME/"
        sudo rsync $RSYNC_OPTS "$SRC/" "$DEST/$BASENAME/"
    else
        echo -e "${RED}⚠️ バックアップ元が見つかりません: $SRC${NC}"
    fi
done

echo -e "${GREEN}✅ バックアップ完了！保存先: $DEST${NC}"

# アンマウント処理
echo "🔌 メディアをアンマウント中..."
sudo umount "$MOUNT_POINT"

echo -e "${GREEN}📤 メディアを安全に取り外せます。${NC}"

