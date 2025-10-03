# プライバシーポリシー

最終更新日: 2025年10月3日

## はじめに

「カフェどこ？」（以下、「本アプリ」）は、ユーザーのプライバシーを尊重し、個人情報の保護に努めています。本プライバシーポリシーは、本アプリが収集、使用、共有する情報について説明します。

## 開発者情報

- アプリ名: カフェどこ？
- 開発者: Cafe Doko
- 連絡先: https://github.com/hakunama0/cafe-doko/issues

## 収集する情報

### 1. 位置情報

**収集する情報:**
- ユーザーの現在地（緯度・経度）

**収集目的:**
- 近くのカフェを検索するため
- Google Places APIで周辺のカフェ情報を取得するため

**使用方法:**
- アプリ内でのみ使用
- Google Places APIへのリクエストパラメータとして送信
- サーバーへの保存は一切行いません

**オプトアウト:**
- iOS設定 → プライバシーとセキュリティ → 位置情報サービスから、本アプリの位置情報アクセスを無効化できます
- 位置情報を無効化した場合、デフォルト位置（東京駅）からの検索になります

### 2. ローカルストレージデータ

**収集する情報:**
- お気に入りカフェのID・名前
- 閲覧履歴（カフェID・名前・閲覧日時）
- アプリ設定（表示モード、ソート順、通知設定）

**保存場所:**
- すべてユーザーのデバイス内（UserDefaults）に保存
- クラウドやサーバーへの送信は一切行いません

**削除方法:**
- 設定 → データ → 「お気に入りをリセット」
- 設定 → データ → 「設定をリセット」
- アプリをアンインストールすることですべてのデータが削除されます

## 収集しない情報

本アプリは以下の情報を**一切収集しません**:

- 名前、メールアドレス、電話番号などの個人を特定する情報
- パスワードやログイン情報
- クレジットカード情報
- 写真や連絡先
- デバイスID、広告ID
- アプリの使用状況（アナリティクス）
- クラッシュレポート

## 第三者サービス

### Google Places API

本アプリは、Google Places APIを使用してカフェ情報を取得しています。

**送信する情報:**
- ユーザーの現在位置（緯度・経度）
- 検索パラメータ（カフェ、検索半径）

**Google のプライバシーポリシー:**
- https://policies.google.com/privacy

**使用目的:**
- 近くのカフェの位置情報、名前、営業時間、電話番号などを取得

### Supabase

本アプリは、Supabaseを使用してカフェチェーンのメニュー・価格情報を取得しています。

**送信する情報:**
- なし（公開APIからの読み取りのみ）

**使用目的:**
- カフェチェーンのメニュー・価格情報の表示

## データの共有

本アプリは、ユーザーの個人情報を第三者と共有、販売、レンタルすることは**一切ありません**。

ただし、以下の場合を除きます:
- 法律で義務付けられている場合
- ユーザーの同意がある場合

## データのセキュリティ

- 位置情報はHTTPS通信で暗号化されています
- ローカルストレージデータはデバイス内に安全に保存されます
- サーバーへの個人情報の送信は一切行いません

## 子供のプライバシー

本アプリは、13歳未満の子供から故意に個人情報を収集することはありません。13歳未満のお子様が本アプリを使用する場合は、保護者の監督のもとで使用してください。

## プライバシーポリシーの変更

本プライバシーポリシーは、予告なく変更される場合があります。変更後のプライバシーポリシーは、本ページに掲載された時点で効力を生じます。

## お問い合わせ

プライバシーポリシーに関するご質問やご意見は、以下までお問い合わせください:

GitHub Issues: https://github.com/hakunama0/cafe-doko/issues

---

## 英語版 (English)

### Privacy Policy

**Last Updated:** October 3, 2025

**App Name:** Cafe Doko (カフェどこ？)

**Developer:** Cafe Doko

**Contact:** https://github.com/hakunama0/cafe-doko/issues

### Information We Collect

**Location Information:**
- Current location (latitude/longitude) for finding nearby cafes
- Sent to Google Places API only
- Not stored on any server

**Local Storage:**
- Favorite cafes, viewing history, app settings
- Stored locally on your device only
- Never sent to any server

### Information We Don't Collect

- Personal identification information
- Passwords or login credentials
- Payment information
- Photos or contacts
- Device IDs or advertising IDs
- Usage analytics
- Crash reports

### Third-Party Services

**Google Places API:**
- Used to fetch nearby cafe information
- Privacy Policy: https://policies.google.com/privacy

**Supabase:**
- Used to fetch cafe menu and pricing information
- Read-only public API access

### Data Sharing

We do not share, sell, or rent your personal information to third parties.

### Contact

For privacy-related questions: https://github.com/hakunama0/cafe-doko/issues

---

© 2025 Cafe Doko

