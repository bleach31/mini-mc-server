#!/bin/bash

# 設定
SWAP_SIZE="4G"
INSTALL_DIR="/opt/minecraft"
SERVICE_FILE="minecraft.service"

echo "=== 1. スワップ領域の作成 ($SWAP_SIZE) ==="
if [ ! -f /swapfile ]; then
    fallocate -l $SWAP_SIZE /swapfile
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
    echo '/swapfile none swap sw 0 0' >> /etc/fstab
    echo "スワップを作成しました。"
else
    echo "スワップは既に存在します。"
fi

echo "=== 2. 必要パッケージのインストール ==="
apt-get update
# Bedrockサーバーに必要なライブラリと便利ツール
apt-get install -y curl unzip wget libcurl4

echo "=== 3. ディレクトリ作成 ==="
mkdir -p $INSTALL_DIR
# アップデートスクリプトを配置
cp update_bedrock.sh $INSTALL_DIR/
chmod +x $INSTALL_DIR/update_bedrock.sh

echo "=== 4. Systemdサービス登録 ==="
cp $SERVICE_FILE /etc/systemd/system/
systemctl daemon-reload
systemctl enable minecraft

echo "=== 5. 初回インストール実行 ==="
bash $INSTALL_DIR/update_bedrock.sh

echo "=== 完了 ==="
echo "サーバーが起動しているか確認してください: sudo systemctl status minecraft"