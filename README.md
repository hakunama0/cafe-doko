# カフェどこ？ iOSアプリ

近くのカフェを価格・距離・営業時間で比較し、最適なカフェを見つけることができる iOS アプリです。SwiftUI と MapKit を活用し、リスト表示と地図表示を切り替えながら、お気に入り機能で自分好みのカフェを管理できます。

## 主な機能

### 🗺️ リスト・地図ビュー
- カフェ一覧をカード形式で表示
- 地図ビューに切り替えてピンで位置を確認
- タップで詳細情報を表示

### ⭐ お気に入り機能
- カフェをお気に入りに登録・削除
- お気に入りフィルタで登録したカフェのみ表示
- UserDefaults で永続化

### 🔍 検索・ソート
- 店名やタグで検索
- 価格順・距離順・おすすめ順でソート
- リアルタイムフィルタリング

### 🕒 営業時間表示
- 営業中/閉店中バッジをリアルタイム表示
- 営業時間の詳細表示
- 曜日・時間帯ごとの判定

### 📍 詳細情報
- 住所・電話番号・営業時間
- 地図アプリ連携（住所タップで起動）
- 電話アプリ連携（電話番号タップで発信）

## 技術スタック
- **言語:** Swift 5.10 以降
- **UI:** SwiftUI + Observation API + iOS 26 Liquid Glass
- **地図:** MapKit
- **アーキテクチャ:** アプリシェル + Core + Feature モジュール構成
- **データ層:** `CafeDataProviding` プロトコルでデータ源を抽象化（Remote API/Mock）
- **バックエンド:** Supabase REST API
- **ビルド:** `project.yml` から [XcodeGen](https://github.com/yonaskolb/XcodeGen) で Xcode プロジェクトを生成
- **自動化:** Cursor Rules と MCP による TODO / ワークフロー連携

## セットアップ手順
1. 依存ツールのインストール
   ```bash
   brew install xcodegen
   ```
2. Xcode プロジェクトを生成
   ```bash
   xcodegen generate
   open CafeDoko.xcodeproj
   ```
3. `CafeDokoApp` スキームを iOS 18 シミュレータ（将来的には iOS 26 へ更新予定）でビルド＆実行
4. データソースは `Config/cafe-doko-config.json` で `mock`/`remote` を切り替え可能（未作成の場合はモック JSON が使用されます）

## ディレクトリ構成
- `project.yml` — Xcode プロジェクトの単一ソース
- `App/` — アプリエントリポイントと SwiftUI ルートシーン
- `Features/` — 機能別モジュール群（初期状態では `Core` モジュールのみ）
- `Resources/` — アセットカタログおよび共通リソース
- `Docs/` — Cursor Rules、MCP 用 TODO、設計資料など

## Cursor と MCP の活用
- 共有ルールは `Docs/cursor-rules.md` を参照
- TODO 管理は `Docs/todo.mcp.json`（MCP 互換形式）で行い、エージェントと同期
- 設計判断は `Docs/adr` 以下に ADR として記録（必要に応じて作成）

## MCP CLI ツール

プロジェクトには MCP (Model Context Protocol) 対応の CLI ツールが含まれています：

```bash
# タスク一覧表示
swift Tools/mcp-cli/main.swift list

# ステータスでフィルタ
swift Tools/mcp-cli/main.swift list --status=in_progress

# タスク詳細表示
swift Tools/mcp-cli/main.swift show DC-001

# タスクステータス更新
swift Tools/mcp-cli/main.swift update DC-001 done
```

詳細は `Tools/mcp-cli/README.md` を参照してください。

## ログとメトリクスの確認

アプリのログ確認とパフォーマンスメトリクスについては、**Observability ガイド**を参照してください：

```bash
# Console.app での確認方法
open Docs/observability-guide.md

# ログをエクスポート
swift Tools/log-exporter/main.swift --format=json > logs.json
```

主な機能：
- 📊 **Console.app での即座にログ確認**
- 📁 **JSON/テキスト形式でログエクスポート**
- 📈 **メトリクス定義とKPI**（レスポンスタイム、成功率など）
- 🔍 **ログ分析クエリ例**（jqを使用）

詳細は [`Docs/observability-guide.md`](Docs/observability-guide.md) を参照してください。

## アーキテクチャ

### モジュール構成
```
CafeDokoApp (App Shell)
├── CafeDokoCore (共通機能)
│   ├── RootAppModel (アプリ全体の状態管理)
│   ├── FavoritesManager (お気に入り管理)
│   ├── BusinessHoursParser (営業時間パース)
│   └── MCPBridge (タスク管理連携)
└── DokoCafeFeature (カフェ機能)
    ├── DokoCafeViewModel (カフェデータ管理)
    ├── CafeDataProviding (データソース抽象化)
    │   ├── RemoteCafeDataProvider (Supabase API)
    │   └── EmptyCafeDataProvider (フォールバック)
    └── CafeImageProviding (画像表示)
```

### データフロー
1. `RemoteCafeDataProvider` が Supabase REST API からカフェデータを取得
2. `DokoCafeViewModel` がデータを管理し、ソート・フィルタを適用
3. `ContentView` がリスト/マップビューを表示
4. `FavoritesManager` がお気に入り状態を永続化
5. `BusinessHoursParser` が営業時間を判定

## API設定

### Supabase接続
環境変数を `Config/.secrets/secrets.env` に設定：
```bash
CAFE_DOKO_API_KEY=your_supabase_anon_key
```

`Config/cafe-doko-config.json` で接続先を設定：
```json
{
  "dataProvider": "remote",
  "remote": {
    "url": "https://your-project.supabase.co/rest/v1/cafes?select=*",
    "headers": {
      "apikey": "${CAFE_DOKO_API_KEY}",
      "X-API-Key": "${CAFE_DOKO_API_KEY}"
    }
  }
}
```

## 今後の予定
- 実際の座標データを使った精密な地図表示
- 営業時間の自動更新
- カフェレビュー・評価機能
- 訪問履歴の記録
- プッシュ通知（お気に入りカフェの営業開始など）
