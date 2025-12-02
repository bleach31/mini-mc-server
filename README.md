# Minimal Minecraft Bedrock Server Setup

Google Cloud Platform (GCP) の無料枠 (`e2-micro` インスタンス) を利用して、Minecraft Bedrock Edition (統合版) サーバーを構築・運用するためのスクリプトセットです。

メモリ不足によるクラッシュを防ぐスワップ設定や、手間のかかるアップデート作業の自動化を含んでいます。

## 特徴
* **完全自動セットアップ:** 依存パッケージ導入、スワップ領域(4GB)作成、サーバーインストール、サービス化をスクリプト1発で実行。
* **自動アップデート:** 公式サイトから最新のバイナリを取得し、ワールドデータを保持したまま更新するスクリプト付属。
* **自動復旧:** サーバーダウン時やVM再起動時に自動で立ち上がるSystemd設定。

## 事前準備 (GCP設定)
GCPコンソールで以下の構成のVMインスタンスを作成してください。

* **リージョン:** `us-west1` (オレゴン) 推奨
* **マシンタイプ:** `e2-micro` (2 vCPU, 1 GB memory)
* **ブートディスク:** Ubuntu 22.04 LTS **Minimal** (30GB / 標準永続ディスク)
* **ファイアウォール:** UDP `19132` ポートを開放
* **ネットワーク:** スタンダードティア (Standard Tier) ※推奨

## インストール手順

VMにSSH接続し、以下のコマンドを実行してください。

```bash
# 1. rootになる
sudo -i

# 2. gitのインストール
apt-get update && apt-get install -y git

# 3. リポジトリのクローン (URLは適宜変更してください)
git clone [https://github.com/your-account/minecraft-bedrock-gcp.git](https://github.com/your-account/minecraft-bedrock-gcp.git)
cd minecraft-bedrock-gcp

# 4. セットアップの実行
bash setup.sh
```

インストールが完了すると、自動的にサーバーが起動します。

## 運用方法

### 自動アップデートの設定 (Cron)

毎日深夜 (例: 朝4時) にアップデートを確認するように設定します。

```bash
crontab -e
```

以下の行を末尾に追加してください。

```cron
0 4 * * * /bin/bash /opt/minecraft/update_bedrock.sh >> /opt/minecraft/update.log 2>&1
```

### 手動アップデート

いつでも手動で最新版に更新できます。

```bash
sudo bash /opt/minecraft/update_bedrock.sh
```

### サーバーの操作コマンド

  * **ステータス確認:** `systemctl status minecraft`
  * **起動:** `systemctl start minecraft`
  * **停止:** `systemctl stop minecraft`
  * **再起動:** `systemctl restart minecraft`

### 設定の変更

サーバーの設定 (難易度、人数制限など) は以下のファイルを編集し、再起動してください。

```bash
nano /opt/minecraft/server.properties
```

**推奨設定 (e2-micro向け):**
ラグを減らすため、視界距離 (`view-distance`) をデフォルトの `32` から `10` 以下に下げることを強く推奨します。

```properties
view-distance=10
```

## ファイル構成

  * `setup.sh`: 初回構築用スクリプト (Swap作成、Systemd登録)
  * `update_bedrock.sh`: アップデート＆バックアップ用スクリプト
  * `minecraft.service`: Systemdサービス定義ファイル

## 免責事項

本スクリプトは学習・検証用です。Google Cloudの課金状況やワールドデータの破損については自己責任で管理してください。

```