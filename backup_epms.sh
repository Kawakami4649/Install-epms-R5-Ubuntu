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

DEVICE=""
AUTO_YES=false

# 引数解析
while [[ $# -gt 0 ]]; do
  case "$1" in
    --device)
      DEVICE="$2"
      shift 2
      ;;
    --yes)
      AUTO_YES=true
      shift
      ;;
    *)
      echo -e "${RED}❌ 不明な引数: $1${NC}"
      exit 1
      ;;
  esac
done

# デバイスが指定されていなければ自動検出
if [ -z "$DEVICE" ]; then
  echo -e "${GREEN}🔍 外部メディアをスキャン中...${NC}"
  DEVICE=$(lsblk -dpno NAME | grep "disk" | grep -v "/dev/sda" | head -n 1)
  if [ -z "$DEVICE" ]; then
    echo -e "${RED}❌ 外部メディアが見つかりません。${NC}"
    exit 1
  fi
fi

echo "💽 使用デバイス: $DEVICE"

# パーティション取得
PART=""
for i in {1..5}; do
  PART=$(lsblk -lnpo NAME "$DEVICE" | grep -E "^$DEVICE(p[0-9]+|[0-9]+)$" | head -n 1)
  if [ -n "$PART" ]; then
    break
  fi
  sleep 1
done

# パーティションがなければ作成してフォーマット
if [ -z "$PART" ]; then
  if [ "$AUTO_YES" = true ]; then
    echo -e "${GREEN}🛠️ パーティションが存在しません。作成してフォーマットします。${NC}"
    echo "🧹 既存の署名を消去中..."
    sudo wipefs -a "$DEVICE"

    echo "🔧 パーティション作成中..."
    echo -e "o\nn\np\n1\n\n\nw" | sudo fdisk "$DEVICE"

    echo "🔄 パーティション情報を再読み込み中..."
    sudo partprobe "$DEVICE"
    sleep 2

    # 再取得
    for i in {1..5}; do
      PART=$(lsblk -lnpo NAME "$DEVICE" | grep -E "^$DEVICE(p[0-9]+|[0-9]+)$" | head -n 1)
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
  else
    echo -e "${RED}⚠️ パーティションが存在しません。--yes を指定して自動作成できます。${NC}"
    exit 1
  fi
fi

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

