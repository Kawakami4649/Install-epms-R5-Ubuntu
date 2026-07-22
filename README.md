# Install-epms-R5-Ubuntu README

## 概要

`Install-epms-R5-Ubuntu` は、Ubuntu 上に E-POST Mail Server V (メールサーバシステム) をRasberry pi 5 + Ubuntu Server へインストールするためのセットアップパッケージです。

以下の機能を提供します。

* EPMS 本体のインストール
* Web管理画面の導入
* DMARC ライブラリ導入
* SSL証明書の生成
* systemd サービス登録
* 定期処理(cron)設定
* バックアップ／リストア
* 初期化（再インストール）

---

## ファイル構成

| ファイル                              | 内容            |
| --------------------------------- | ------------- |
| install.sh                        | EPMS本体のインストール |
| epms-R5-Ubuntu.tar.gz             | EPMS本体        |
| epstman_cgi.tar.gz                | Web管理画面       |
| dmarc-lib.tar.gz                  | DMARCライブラリ    |
| SysPassword.tar.gz                | パスワード関連ファイル   |
| add_ssl_reg.tar.gz                | SSL設定追加       |
| create_cert.sh                    | 自己署名証明書作成     |
| renew_cert.sh                     | 証明書更新         |
| add_cron.sh                       | 定期ジョブ登録       |
| remove_cron.sh                    | 定期ジョブ削除       |
| backup_epms.sh                    | バックアップ        |
| restore_epms.sh                   | リストア          |
| reset_epms.sh                     | 再インストール       |
| format_media.sh                   | 外部メディア初期化     |
| restore_epms1.sh                  | 別リストア処理       |
| backup_epms1.sh                   | 別バックアップ処理     |
| epms-R5-Ubuntu-bin-diff-*.tar.gz  | バイナリ差分更新      |
| epms-R5-Ubuntu-html-diff-*.tar.gz | Web画面差分更新     |

---

# 動作環境

* Ubuntu
* systemd対応環境
* OpenSSL
* rsync
* fdisk
* partprobe

管理者権限(sudo)が必要です。

---

# インストール

展開後、

```bash
cd Install-epms-R5-Ubuntu
sudo ./install.sh
```

を実行します。

---

# インストール内容

### 1. EPMS本体展開

```text
/usr/local/mta/
/var/spool/epms/
```

へ各種ファイルを配置します。

### 2. Web管理画面導入

```text
/var/www/html/epms/
```

を構成します。

### 3. systemdサービス登録

以下を自動有効化します。

* epstrd.service
* epstdd.service
* epstpop3d.service
* epstimap4d.service

```bash
systemctl enable epstrd
systemctl enable epstdd
systemctl enable epstpop3d
systemctl enable epstimap4d
```

---

# SSL証明書生成

インストール時に

```bash
create_cert.sh chat.local
```

が実行され、

```
/etc/ssl/private/chat.local.key
/etc/ssl/certs/chat.local.crt
```

が生成されます。

有効期限は 180 日です。

---

## 手動作成

```bash
sudo create_cert.sh example.local
```

生成されるファイル

```text
/etc/ssl/private/example.local.key
/etc/ssl/certs/example.local.crt
```

---

# 証明書更新

```bash
sudo renew_cert.sh example.local
```

秘密鍵と証明書を再生成します。

---

# バックアップ

## 実行

```bash
sudo backup_epms.sh
```

または

```bash
sudo backup_epms.sh --device /dev/sdb
```

### 自動パーティション作成を許可

```bash
sudo backup_epms.sh --yes
```

---

## バックアップ対象

### プログラム

```text
/usr/local/mta/bin
```

### メールデータ

```text
/var/spool/epms
```

---

## 保存先

外部メディアを

```text
/media/pi
```

へマウントし、

```text
backup_YYYY-MM-DD_HH-MM
```

形式のフォルダへ保存します。

例

```text
/media/pi/backup_2026-06-18_12-00/
```

---

# リストア

```bash
sudo restore_epms.sh
```

または

```bash
sudo restore_epms.sh --device /dev/sdb
```

最新の

```text
backup_*
```

ディレクトリを自動検出し、

以下を復元します。

```text
/usr/local/mta/bin
/var/spool/epms
```

---

# EPMS初期化

完全再インストールを行う場合

```bash
sudo reset_epms.sh
```

を実行します。

以下を削除します。

```text
/usr/local/mta/
/var/www/html/epms/
/var/spool/epms/
```

その後、

```text
install.sh
```

を再実行し、サービスを起動します。

---

# 差分更新

インストール時に以下の更新パッケージが適用されます。

### バイナリ更新

```text
epms-R5-Ubuntu-bin-diff-20260611.tar.gz
```

配置先

```text
/usr/local/mta/bin/
```

### Web画面更新

```text
epms-R5-Ubuntu-html-diff-20260429.tar.gz
```

配置先

```text
/var/www/html/
```

---

# サービス操作

起動

```bash
sudo systemctl start epstrd
sudo systemctl start epstdd
sudo systemctl start epstpop3d
sudo systemctl start epstimap4d
```

停止

```bash
sudo systemctl stop epstrd
sudo systemctl stop epstdd
sudo systemctl stop epstpop3d
sudo systemctl stop epstimap4d
```

状態確認

```bash
systemctl status epstrd
systemctl status epstdd
systemctl status epstpop3d
systemctl status epstimap4d
```

---

# ディレクトリ構成

```text
/usr/local/mta/          EPMS本体
/var/spool/epms/         メールデータ
/var/www/html/epms/      Web管理画面
/etc/ssl/private/        秘密鍵
/etc/ssl/certs/          証明書
/media/pi/               バックアップ媒体
```

---

# 注意事項

* インストールには root 権限が必要です。
* SSL証明書は自己署名証明書です。
* バックアップには外部USBメディアが必要です。
* `reset_epms.sh` はメールデータを削除するため、実行前にバックアップを取得してください。
* バックアップ／リストアは `rsync --delete` を使用するため、復元先の不要ファイルは削除されます。
* Ubuntu + systemd 環境を前提としています。

