# Google Places API セットアップガイド

## 1. Google Cloud Console でプロジェクト作成

1. https://console.cloud.google.com/ にアクセス
2. 新しいプロジェクトを作成（例: `cafedoko-app`）
3. プロジェクトを選択

## 2. Places API (New) を有効化

1. 「APIとサービス」→「ライブラリ」
2. "Places API (New)" を検索
3. 「有効にする」をクリック

## 3. APIキーを作成

1. 「APIとサービス」→「認証情報」
2. 「認証情報を作成」→「APIキー」
3. 作成されたAPIキーをコピー
4. （推奨）「キーを制限」をクリック
   - アプリケーションの制限: iOSアプリ
   - バンドルID: `com.cafedoko.app`
   - API制限: Places API (New)

## 4. 環境変数に設定

```bash
# Config/.secrets/secrets.env に追加
GOOGLE_PLACES_API_KEY=YOUR_API_KEY_HERE
```

## 5. 無料クレジット

- 新規登録で $300 の無料クレジット（90日間有効）
- 毎月 $200 の無料枠
- Places API (New) Nearby Search: $7/1000リクエスト

## 6. テスト方法

```bash
# cURLでテスト
curl -X POST \
  'https://places.googleapis.com/v1/places:searchNearby' \
  -H 'Content-Type: application/json' \
  -H 'X-Goog-Api-Key: YOUR_API_KEY' \
  -H 'X-Goog-FieldMask: places.displayName,places.formattedAddress,places.location' \
  -d '{
    "includedTypes": ["cafe"],
    "maxResultCount": 5,
    "locationRestriction": {
      "circle": {
        "center": {
          "latitude": 35.6812,
          "longitude": 139.7671
        },
        "radius": 500.0
      }
    }
  }'
```

## 次のステップ

APIキー取得後：
1. `Config/.secrets/secrets.env` に `GOOGLE_PLACES_API_KEY` を追加
2. Swift実装で Places API を統合
3. 取得した店舗情報とSupabaseのチェーンデータをマッチング

