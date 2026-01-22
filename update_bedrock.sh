#!/bin/bash

INSTALL_DIR="/opt/minecraft"
BACKUP_DIR="$INSTALL_DIR/backups"
WIKI_URL="https://minecraft.wiki/w/Bedrock_Dedicated_Server"
# 偽装用のUser-Agent
UA="Mozilla/5.0 (Windows NT 10.0; Win64; x64)"

mkdir -p $BACKUP_DIR
cd $INSTALL_DIR

# --- A. 最新バージョンの確認 (Wikiから抽出 + ソート) ---
echo "公式Wikiから最新リンクを探しています..."

# Wikiから全リンクを取得 -> バージョン順にソート -> 最新の1つを取得
DOWNLOAD_URL=$(curl -H "User-Agent: $UA" -s "$WIKI_URL" | grep -o 'https://www.minecraft.net/bedrockdedicatedserver/bin-linux/bedrock-server-[0-9.]*\.zip' | sort -V | tail -n 1)

if [ -z "$DOWNLOAD_URL" ]; then
    echo "エラー: ダウンロードURLが見つかりませんでした。"
    echo "手動で実行してください: sudo bash update_bedrock.sh <バージョン番号>"
    exit 1
fi

ZIP_NAME=$(basename "$DOWNLOAD_URL")
echo "検出された最新バージョンURL: $DOWNLOAD_URL"
echo "ファイル名: $ZIP_NAME"

# --- B. 既にダウンロード済みかチェック ---
if [ -f "$ZIP_NAME" ]; then
    echo "既に最新版 ($ZIP_NAME) が存在します。アップデートは不要です。"
    exit 0
fi

echo "ダウンロードを開始します..."
wget -nv --user-agent="$UA" "$DOWNLOAD_URL" -O "$ZIP_NAME"

if [ ! -f "$ZIP_NAME" ] || [ ! -s "$ZIP_NAME" ]; then
    echo "ダウンロードに失敗しました（ファイルが空か存在しません）。"
    rm -f "$ZIP_NAME"
    exit 1
fi

# --- C. サーバー停止とバックアップ ---
echo "サーバーを停止します..."
systemctl stop minecraft

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
chmod +x bedrock_server

# --- E. サーバー起動 ---
echo "サーバーを起動します..."
systemctl start minecraft
echo "作業完了！"
