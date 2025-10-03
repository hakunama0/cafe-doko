# カフェどこ？ Observability ガイド

このドキュメントでは、カフェどこ？アプリのログ確認方法とメトリクス定義について説明します。

## ログ確認方法

### 1. Console.app（macOS）

**手順：**

1. **Console.app を開く**
   ```bash
   open /System/Applications/Utilities/Console.app
   ```

2. **フィルタを設定**
   - 左サイドバーで「このMac」またはシミュレータを選択
   - 検索バーに以下を入力：
     ```
     subsystem:com.cafedoko.app category:RemoteCafeDataProvider
     ```

3. **ログレベルを選択**
   - 上部メニューから「アクション」→「情報メッセージを含める」をON
   - エラーのみ見たい場合は「アクション」→「デバッグメッセージを含める」をOFF

**便利なフィルタ例：**

```
# エラーのみ
subsystem:com.cafedoko.app AND messageType:error

# フェッチ成功のみ
subsystem:com.cafedoko.app AND message CONTAINS "Fetched"

# 特定のURL
subsystem:com.cafedoko.app AND message CONTAINS "supabase.co"
```

### 2. ログエクスポートツール

**テキスト形式でエクスポート：**
```bash
swift Tools/log-exporter/main.swift
```

**JSON形式でエクスポート：**
```bash
swift Tools/log-exporter/main.swift --format=json > logs.json
```

**過去48時間のログ：**
```bash
swift Tools/log-exporter/main.swift --hours=48
```

**ヘルプ：**
```bash
swift Tools/log-exporter/main.swift --help
```

### 3. Xcode コンソール

1. Xcode でアプリを実行
2. 下部のコンソールエリアで `com.cafedoko.app` を検索
3. フィルタアイコンをクリックして設定

## メトリクス定義

### API パフォーマンス

| メトリクス名 | 説明 | 単位 | 目標値 |
|------------|------|-----|-------|
| `api.fetch.duration` | API リクエストの所要時間 | ms | < 1000ms |
| `api.fetch.success_rate` | API リクエストの成功率 | % | > 99% |
| `api.fetch.error_rate` | API リクエストのエラー率 | % | < 1% |
| `api.fetch.count` | API リクエストの実行回数 | count | - |

### エラー分類

| エラータイプ | ログメッセージ | 対応優先度 |
|------------|-------------|----------|
| `Network Error` | `Request error:` | 高 |
| `Status Code Error` | `Request failed with status` | 中 |
| `Decoding Error` | `Decoding error:` | 高 |
| `Invalid Response` | `Invalid response type` | 高 |

### ログフォーマット

#### 成功ログ

```
[2025-10-03T07:00:00Z] ℹ️ [RemoteCafeDataProvider] Fetching cafes from https://dlwjajmdqopypgzkiwut.supabase.co/rest/v1/cafes?select=*
[2025-10-03T07:00:01Z] ℹ️ [RemoteCafeDataProvider] Fetched 3 cafes in 234 ms
```

**抽出すべき情報：**
- リクエストURL
- 取得件数
- レスポンス時間（ms）

#### エラーログ

```
[2025-10-03T07:00:00Z] ❌ [RemoteCafeDataProvider] Request failed with status 401 message: Invalid API key
```

**抽出すべき情報：**
- HTTPステータスコード
- エラーメッセージ
- タイムスタンプ

## ダッシュボード連携（将来対応）

### オプション1: Grafana + Loki

1. **Loki へのログ送信**
   - JSON形式でエクスポート
   - promtail でログを収集
   - Loki へ転送

2. **Grafana ダッシュボード**
   - API レスポンスタイムのグラフ化
   - エラー率の可視化
   - アラート設定

### オプション2: Datadog / New Relic

- iOS SDK を統合
- リアルタイムメトリクス収集
- APM（Application Performance Monitoring）

### オプション3: Apple の TelemetryKit

- iOS 17+ で利用可能
- Apple推奨の方法
- TestFlight や App Store Connect と統合

## ログ分析クエリ例

### 平均レスポンス時間の計算

```bash
# JSON形式でエクスポート後、jq で処理
swift Tools/log-exporter/main.swift --format=json | \
  jq '[.[] | select(.message | contains("Fetched")) | 
       (.message | capture("(?<time>[0-9]+) ms").time | tonumber)] | 
      add / length'
```

### エラー率の計算

```bash
# エラー件数 / 全リクエスト件数
swift Tools/log-exporter/main.swift --format=json | \
  jq '[.[] | select(.category == "RemoteCafeDataProvider")] | 
      {total: length, errors: [.[] | select(.level == "error")] | length} | 
      .errors / .total * 100'
```

### ステータスコード別の集計

```bash
swift Tools/log-exporter/main.swift --format=json | \
  jq '[.[] | select(.message | contains("status")) | 
       .message | capture("status (?<code>[0-9]+)").code] | 
      group_by(.) | map({status: .[0], count: length})'
```

## トラブルシューティング

### ログが表示されない

1. **アプリが実行されているか確認**
   - シミュレータまたは実機でアプリを起動
   - API リクエストを実行（リスト更新）

2. **ログレベルの確認**
   - Console.app で「情報メッセージを含める」がONか確認
   - デバッグビルドでない場合、ログが削減される可能性

3. **サブシステムの確認**
   - フィルタが `com.cafedoko.app` になっているか確認

### ログエクスポートが失敗する

1. **macOS バージョン確認**
   - macOS 12.0+ が必要
   - `sw_vers` で確認

2. **権限の確認**
   - ログへのアクセス権限が必要
   - 必要に応じて「システム設定」→「プライバシーとセキュリティ」で許可

## 参考リンク

- [Apple Developer: Logging](https://developer.apple.com/documentation/os/logging)
- [OSLogStore Documentation](https://developer.apple.com/documentation/oslog/oslogstore)
- [Console User Guide](https://support.apple.com/guide/console/welcome/mac)

