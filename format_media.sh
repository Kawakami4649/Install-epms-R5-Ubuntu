#!/bin/bash

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}🔍 外部メディアをスキャン中...${NC}"

DEVICES=$(lsblk -dpno NAME,TYPE | grep "disk" | grep -v "/dev/sda" | awk '{print $1}')

if [ -z "$DEVICES" ]; then
    echo -e "${RED}❌ 外部メディアが見つかりません。${NC}"
    exit 1
fi

echo "✅ 検出されたデバイス："
echo "$DEVICES"
echo ""

echo "🧭 フォーマットするデバイスを選んでください："
select DEV in $DEVICES; do
    if [ -n "$DEV" ]; then
        echo "選択されたデバイス: $DEV"
        break
    else
        echo "無効な選択です。"
    fi
done

echo ""
echo "📦 フォーマット形式を選んでください："
echo "1) ext4"
echo "2) exFAT"
echo "3) FAT32"

read -p "番号を入力（1〜3）: " FORMAT_CHOICE

case $FORMAT_CHOICE in
    1)
        FSTYPE="ext4"
        CMD="mkfs.ext4"
        ;;
    2)
        FSTYPE="exfat"
        CMD="mkfs.exfat"
        ;;
    3)
        FSTYPE="vfat"
        CMD="mkfs.vfat"
        ;;
    *)
        echo -e "${RED}❌ 無効な選択です。${NC}"
        exit 1
        ;;
esac

read -p "💡 ボリュームラベルを入力してください（例：pi）: " LABEL

echo ""
echo -e "${GREEN}⚠️ $DEV を $FSTYPE 形式でフォーマットします。すべてのデータが消去されます。${NC}"
read -p "続行しますか？（yes/no）: " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "⛔ 中止しました。"
    exit 0
fi

echo "🔌 アンマウント中..."
sudo umount "${DEV}"* 2>/dev/null

echo "💽 フォーマット中..."
if [ "$FSTYPE" = "ext4" ]; then
    sudo $CMD -F -L "$LABEL" "$DEV"
else
    sudo $CMD -n "$LABEL" "$DEV"
fi

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ フォーマットに失敗しました。${NC}"
    exit 1
fi

# マウント処理
MOUNT_POINT="/media/${LABEL}"
echo "📂 マウントポイント: $MOUNT_POINT"

sudo mkdir -p "$MOUNT_POINT"

# パーティション名を取得（例：/dev/sdb1）
PART=$(lsblk -lnpo NAME "$DEV" | grep -v "$DEV" | head -n 1)

# パーティションが見つからなければ、デバイス本体を使う
if [ -z "$PART" ]; then
    echo "⚠️ パーティションが見つかりません。デバイス全体をマウント対象にします。"
    PART="$DEV"
fi

echo "🔗 マウント中: $PART → $MOUNT_POINT"
sudo mount "$PART" "$MOUNT_POINT"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ マウント成功！バックアップ先として使用できます。${NC}"
    echo "📁 使用可能なパス: $MOUNT_POINT"
else
    echo -e "${RED}❌ マウントに失敗しました。${NC}"
fi

