#!/bin/bash

INSTALL_DIR="/opt/minecraft"
BACKUP_DIR="$INSTALL_DIR/backups"
UserAgent="Mozilla/5.0 (Windows NT 10.0; Win64; x64)"

mkdir -p $BACKUP_DIR
cd $INSTALL_DIR

# --- A. 最新版のダウンロードURLを取得 ---
echo "最新バージョンを確認中..."
# 公式ページから linux 用の zip リンクをスクレイピング
DOWNLOAD_URL=$(curl -H "User-Agent: $UserAgent" -s https://www.minecraft.net/en-us/download/server/bedrock | grep -o 'https://minecraft.azureedge.net/bin-linux/[^"]*' | head -n 1)

if [ -z "$DOWNLOAD_URL" ]; then
    echo "URLが見つかりませんでした。処理を中断します。"
    exit 1
fi

ZIP_NAME=$(basename "$DOWNLOAD_URL")

# --- B. 既にダウンロード済みかチェック ---
if [ -f "$ZIP_NAME" ]; then
    echo "既に最新版 ($ZIP_NAME) が適用されています。"
    exit 0
fi

echo "新しいバージョンが見つかりました: $ZIP_NAME"
echo "ダウンロード中..."
wget -q -H "User-Agent: $UserAgent" "$DOWNLOAD_URL" -O "$ZIP_NAME"

# --- C. サーバー停止とバックアップ ---
echo "サーバーを停止します..."
systemctl stop minecraft

# 設定ファイルとワールドデータを一時退避
# (server.properties等は上書きされるため退避必須)
echo "データを退避中..."
mkdir -p temp_save
cp server.properties temp_save/ 2>/dev/null
cp allowlist.json temp_save/ 2>/dev/null
cp permissions.json temp_save/ 2>/dev/null
cp -r worlds temp_save/ 2>/dev/null

# --- D. 展開と復元 ---
echo "新しいサーバーを展開中..."
unzip -o -q "$ZIP_NAME"

echo "データを復元中..."
# 設定ファイル類は「あれば」戻す
[ -f temp_save/server.properties ] && cp temp_save/server.properties .
[ -f temp_save/allowlist.json ] && cp temp_save/allowlist.json .
[ -f temp_save/permissions.json ] && cp temp_save/permissions.json .
[ -d temp_save/worlds ] && cp -r temp_save/worlds .

rm -rf temp_save

# --- E. サーバー起動 ---
echo "サーバーを起動します..."
systemctl start minecraft
echo "アップデート完了！"