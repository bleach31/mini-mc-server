# Minecraft Bedrock Server (GCP)

Google Cloud VM 上で Minecraft Bedrock Dedicated Server を運用するためのスクリプトです。初回セットアップ、systemd 登録、自動アップデートを行います。

## ディレクトリ構成

- Git リポジトリ: `/opt/minecraft/mini-mc-server`
- サーバー本体、ワールド、設定: `/opt/minecraft`
- 更新スクリプト: `/opt/minecraft/update_bedrock.sh`（Git checkout 内のスクリプトへのリンク）

Git checkout とゲームデータを同じ `/opt/minecraft` 配下に置きます。ワールドや設定ファイルは Git に追加しません。`setup.sh` は更新スクリプトを checkout 内のファイルへリンクするため、`git pull` 後は更新処理にも変更が反映されます。

## VM の前提

GCP で Ubuntu VM を作成し、ネットワークのファイアウォールで Bedrock 用 UDP `19132` を必要に応じて許可します。SSH は管理元に制限してください。README の `sudo` コマンドは、SSH 接続ユーザーに sudo 権限があることを前提にしています。

## 新規インストール

SSH で VM に接続し、以下を実行します。リポジトリは `/opt/minecraft/mini-mc-server` に clone し、ゲームデータは `/opt/minecraft` に配置します。

```bash
sudo apt-get update
sudo apt-get install -y git cron curl unzip wget libcurl4
sudo systemctl enable --now cron

sudo mkdir -p /opt/minecraft
sudo git clone https://github.com/bleach31/mini-mc-server.git /opt/minecraft/mini-mc-server
sudo chown -R "$USER":"$USER" /opt/minecraft/mini-mc-server
sudo bash /opt/minecraft/mini-mc-server/setup.sh
```

`setup.sh` は 4 GiB の swap、依存パッケージ、Minecraft の systemd unit を設定し、初回アップデートを実行します。完了後、状態を確認します。

```bash
sudo systemctl status minecraft
```

## Git とアップデート

リポジトリの変更をサーバーへ取り込むときは、SSH ユーザーで次を実行します。

```bash
cd /opt/minecraft/mini-mc-server
git pull --ff-only
```

更新スクリプトはこの checkout を参照します。Bedrock サーバー本体の更新確認は別途 cron で毎日実行できます。

```bash
sudo crontab -e
```

次の行を追加します。

```cron
0 4 * * * /bin/bash /opt/minecraft/update_bedrock.sh >> /opt/minecraft/update.log 2>&1
```

更新スクリプトは導入済みバージョンを `/opt/minecraft/.bedrock_version` に記録し、古い `bedrock-server-*.zip` を削除して最新版の zip だけを残します。手動で確認・更新する場合:

```bash
sudo /opt/minecraft/update_bedrock.sh
```

## サーバーの操作

```bash
sudo systemctl status minecraft
sudo systemctl start minecraft
sudo systemctl stop minecraft
sudo systemctl restart minecraft
```

設定ファイルは `/opt/minecraft/server.properties` です。変更後は `sudo systemctl restart minecraft` を実行します。メモリの少ない VM では `view-distance` や `max-players` を控えめにしてください。

## サーバー移行とバックアップ

移行では Git checkout ではなく、ワールドと `/opt/minecraft` の実データをバックアップします。次の手順はサーバーを停止して整合性のあるアーカイブを作り、再起動します。Bedrock の zip は再取得できるため除外し、Git checkout も移行先で clone し直すため除外します。

### 移行元でバックアップを作る

```bash
sudo systemctl stop minecraft
STAMP=$(date +%Y%m%d-%H%M%S)
sudo tar -czf "/tmp/minecraft-${STAMP}.tar.gz" \
  --exclude='minecraft/bedrock-server-*.zip' \
  --exclude='minecraft/mini-mc-server' \
  -C /opt minecraft
sudo tar -tzf "/tmp/minecraft-${STAMP}.tar.gz" >/dev/null
sha256sum "/tmp/minecraft-${STAMP}.tar.gz"
sudo systemctl start minecraft
```

アーカイブにはワールド、設定、現在のサーバーバイナリ、バージョン記録など `/opt/minecraft` の実データが含まれます。作成したアーカイブを `scp` や Cloud Storage で移行先へ転送し、SHA-256 も照合してください。移行元 VM 上だけにバックアップを置かないでください。

### 移行先へ復元する

1. 新しい VM に「新規インストール」の手順を実行します。これにより依存パッケージと systemd unit が設定されます。
2. 転送したアーカイブを移行先 VM に置き、サーバーを停止して `/opt` へ展開します。
3. systemd を再読込してサーバーを起動し、ログインしてワールドと設定を確認します。

```bash
sudo systemctl stop minecraft
sudo tar -xzf /tmp/minecraft-YYYYMMDD-HHMMSS.tar.gz -C /opt
sudo systemctl daemon-reload
sudo systemctl enable minecraft
sudo systemctl start minecraft
sudo systemctl status minecraft
```

展開時は、移行元のワールド、設定、サーバーバイナリが移行先の初期データに上書きされます。移行先で正常に起動し、ワールドを確認するまで移行元 VM とバックアップを削除しないでください。問題があれば移行先を停止し、アーカイブから再度復元します。

## ファイル構成

- `setup.sh`: 初回セットアップと systemd 登録
- `update_bedrock.sh`: 公式最新版の取得とサーバー更新
- `minecraft.service`: systemd unit

## ゲームルール例

管理者権限でサーバー内から実行します。

```text
gamerule keepinventory true
gamerule pvp false
gamerule doweathercycle false
gamerule tntexplodes false
gamerule showcoordinates true
```

## トラブルシューティング

サービスの状態とログを確認します。

```bash
sudo systemctl status minecraft
sudo journalctl -u minecraft -n 100 --no-pager
tail -n 100 /opt/minecraft/update.log
```
