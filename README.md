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

# 2. git, cronのインストール
apt-get update && apt-get install -y git cron

#cronサービスを起動＆自動起動設定
systemctl enable cron
systemctl start cron

# 3. リポジトリのクローン (URLは適宜変更してください)
git clone https://github.com/bleach31/mini-mc-server.git
cd mini-mc-server

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

## サーバー設定 (server.properties)
メモリ1GB環境 (e2-micro) で安定動作させるための軽量化設定および推奨設定。

**File:** `/opt/minecraft/server.properties`

| 項目 | 設定値 | 理由 |
| :--- | :--- | :--- |
| `view-distance` | `12` | **【最重要】** 負荷軽減のため。初期値(32)は重すぎるため必ず下げる。重ければ6へ。 |
| `tick-distance` | `4` | シミュレーション距離の最小化。CPU負荷を大きく下げる。 |
| `max-players` | `5` | メモリ枯渇防止のため、参加人数を制限する。 |

## ゲームルール (Game Rules)
子供同士のトラブル防止（喧嘩・アイテム消失）と、サーバー負荷軽減のための「平和設定」。
※管理者権限でサーバー内チャット、またはSSHコンソールから実行する。

```bash
# 死亡時のアイテムロスト無効 (アイテム消失トラブル防止 & ドロップ計算負荷軽減)
gamerule keepinventory true

# PvP無効 (プレイヤー間の攻撃無効・喧嘩防止)
gamerule pvp false

# 天候固定 (雨/雷の処理負荷カット & 雷による拠点延焼防止)
gamerule doweathercycle false
weather clear

# TNT爆発無効 (地形破壊イタズラ防止)
gamerule tntexplodes false

# 座標表示 (迷子防止)
gamerule showcoordinates true
```

## 免責事項

本スクリプトは学習・検証用です。Google Cloudの課金状況やワールドデータの破損については自己責任で管理してください。

## トラブルシューティング

### Q. `sudo` コマンドでパスワードを求められる、または拒否される

Ubuntu Minimalイメージを使用した場合、初期ユーザーにsudo権限が正しく付与されていない、あるいはパスワード未設定のため認証できない場合があります。

**解決策: GCPの起動スクリプトで権限を強制付与する**

1. Google CloudコンソールでVMインスタンスの **[編集]** をクリックします。
2. **[自動化]** セクションの **「起動スクリプト (Startup script)」** に以下を入力します（`<あなたのユーザー名>` はSSH接続時のユーザー名に書き換えてください）。

```bash
#! /bin/bash
# ユーザーにパスワードなしでのsudo権限を付与
USERNAME="<あなたのユーザー名>"
echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/$USERNAME
chmod 440 /etc/sudoers.d/$USERNAME
```
