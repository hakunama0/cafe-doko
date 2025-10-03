# Google Places API 統合

## 概要

「カフェどこ？」アプリにGoogle Places APIを統合し、リアルタイムで近くのカフェ情報を取得できるようになりました。

## アーキテクチャ

```
┌─────────────────────────────────────────────────────────────┐
│                     CafeDokoApp                              │
│  ┌──────────────────────────────────────────────────────┐  │
│  │             DokoCafeViewModel                         │  │
│  └───────────────────┬──────────────────────────────────┘  │
│                      │                                      │
│  ┌───────────────────▼──────────────────────────────────┐  │
│  │          CafeDataProviding Protocol                   │  │
│  │  ┌──────────────────────────────────────────────┐   │  │
│  │  │ GooglePlacesCafeProvider                      │   │  │
│  │  │  ┌────────────────────────────────────────┐  │   │  │
│  │  │  │    GooglePlacesProvider                │  │   │  │
│  │  │  │    - searchNearbyCafes()               │  │   │  │
│  │  │  │    - API: places:searchNearby          │  │   │  │
│  │  │  └────────────────────────────────────────┘  │   │  │
│  │  └──────────────────────────────────────────────┘   │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                           │
                           ▼
          ┌────────────────────────────────┐
          │   Google Places API (New)      │
          │   places.googleapis.com        │
          └────────────────────────────────┘
                           │
                           ▼
          ┌────────────────────────────────┐
          │   Supabase (価格情報)           │
          │   chains, chain_products       │
          └────────────────────────────────┘
```

## データフロー

1. **ユーザーがアプリを開く**
   - `CafeDokoApp` が起動
   - 設定ファイル (`cafe-doko-config.json`) を読み込み
   - `dataProvider: "google_places"` を検出

2. **Google Places API で検索**
   - `GooglePlacesCafeProvider.fetchChains()` を呼び出し
   - ユーザーの現在地を取得（デフォルト: 東京駅）
   - Google Places API に `searchNearby` リクエスト
   - 半径1km以内のカフェを最大20件取得

3. **データ変換**
   - Google Places の `Place` オブジェクトを `DokoCafeViewModel.Chain` に変換
   - 距離計算、価格推定、タグ生成

4. **価格情報の統合**
   - `ChainMenuService` で Supabase から価格情報を取得
   - カフェ名でチェーンを判定（スタバ、ドトールなど）
   - 正確な価格とメニューを表示

## 実装ファイル

### 1. GooglePlacesProvider.swift

Google Places API (New) の Places (New) API を使用した検索実装。

**主要機能:**
- `searchNearbyCafes(latitude:longitude:radius:maxResults:)`
- JSON レスポンスのデコード
- エラーハンドリング

**使用するAPI:**
```
POST https://places.googleapis.com/v1/places:searchNearby
X-Goog-Api-Key: YOUR_API_KEY
X-Goog-FieldMask: places.id,places.displayName,...
```

**レスポンス例:**
```json
{
  "places": [
    {
      "id": "ChIJ...",
      "displayName": {"text": "スターバックス 東京駅店"},
      "formattedAddress": "東京都千代田区丸の内...",
      "location": {"latitude": 35.6812, "longitude": 139.7671},
      "rating": 4.2,
      "currentOpeningHours": {
        "openNow": true,
        "weekdayDescriptions": ["月曜日: 7:00～21:00", ...]
      }
    }
  ]
}
```

### 2. GooglePlacesCafeProvider.swift

`CafeDataProviding` プロトコルの実装。

**主要機能:**
- `fetchChains()`: Google Places からカフェリストを取得
- `convertToChain()`: データ変換
- `calculateDistance()`: 距離計算
- `estimatePrice()`: 価格レベルから円換算

**価格変換ロジック:**
| Google Places | 日本円（推定） |
|--------------|-------------|
| INEXPENSIVE  | 300円       |
| MODERATE     | 450円       |
| EXPENSIVE    | 600円       |
| VERY_EXPENSIVE | 800円     |

### 3. ChainMenuService.swift

Supabase から正確な価格・メニュー情報を取得。

**主要機能:**
- `fetchChainMenu(chainId:)`: チェーンIDでメニュー取得
- `fetchMenuByCafeName(name:)`: カフェ名から推定

**対応チェーン:**
- スターバックス (`starbucks`)
- ドトール (`doutor`)
- タリーズ (`tullys`)
- コメダ珈琲 (`komeda`)
- エクセルシオール (`excelsior`)

## 設定

### 1. APIキーの設定

`Config/.secrets/secrets.env`:
```bash
GOOGLE_PLACES_API_KEY=AIzaSyB...
CAFE_DOKO_API_KEY=eyJhbGci...  # Supabase
```

### 2. アプリ設定

`Config/cafe-doko-config.json`:
```json
{
  "dataProvider": "google_places",
  "google_places": {
    "api_key": "${GOOGLE_PLACES_API_KEY}",
    "default_radius": 1000,
    "max_results": 20
  },
  "remote": {
    "url": "https://dlwjajmdqopypgzkiwut.supabase.co/rest/v1/cafes?select=*",
    "headers": {
      "apikey": "${CAFE_DOKO_API_KEY}"
    }
  }
}
```

### 3. Info.plist（位置情報）

**TODO:** 実際に位置情報を取得する場合は以下を追加:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>近くのカフェを検索するために位置情報を使用します</string>

<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>バックグラウンドで近くのカフェを通知するために位置情報を使用します</string>
```

## ログとデバッグ

### os_log でのログ出力

```swift
logger.info("🔍 Google Places検索開始: lat=\(latitude), lng=\(longitude)")
logger.info("✅ \(places.count)件のカフェを取得しました")
logger.error("❌ APIエラー: \(errorMessage)")
```

### Console.app でのフィルタ

```
subsystem:com.cafedoko.app category:GooglePlaces
```

## コスト試算

Google Places API (New) の料金:

| 項目 | 価格 | 月間利用例 | コスト |
|-----|------|----------|-------|
| Search Nearby (Basic) | $32 per 1,000 requests | 10,000回 | $320 |
| Field Mask適用 | 追加料金なし | - | - |

**節約ポイント:**
- 必要なフィールドのみ取得（Field Mask）
- キャッシュの活用（5分間有効など）
- リクエスト頻度の制限

**無料枠:**
- 新規アカウントは $300 クレジット（90日間）

## API制限とベストプラクティス

### レート制限

- デフォルト: 1,000 QPM (Queries Per Minute)
- バースト: 最大 100 QPS

### リクエスト最適化

1. **Field Mask の使用**
   ```
   X-Goog-FieldMask: places.id,places.displayName,places.location
   ```
   不要なフィールドを除外してコスト削減。

2. **キャッシュ戦略**
   ```swift
   // 5分間キャッシュ
   if let cached = cache[location], cached.timestamp.addingTimeInterval(300) > Date() {
       return cached.places
   }
   ```

3. **リクエスト頻度制限**
   - ユーザーが移動していない場合は再検索しない
   - Pull-to-Refresh のみ

## トラブルシューティング

### エラー: `PERMISSION_DENIED`

**原因:** APIキーが無効、または制限されている

**解決策:**
1. Google Cloud Console で API が有効か確認
2. APIキーの制限を確認（iOS Bundle ID など）

### エラー: `INVALID_ARGUMENT`

**原因:** リクエストのパラメータが不正

**解決策:**
- `latitude`, `longitude` が有効な範囲内か確認
- Field Mask の構文を確認

### 0件の結果が返る

**原因:**
- 検索範囲内にカフェがない
- `includedTypes: ["cafe"]` で絞りすぎ

**解決策:**
- 検索半径を増やす（1km → 2km）
- タイプを追加: `["cafe", "restaurant"]`

## 今後の拡張

- [ ] 実際の位置情報取得（CLLocationManager）
- [ ] キャッシュ機構の実装
- [ ] オフライン対応（ローカルDBへのフォールバック）
- [ ] 写真取得（Places Photos API）
- [ ] 詳細情報取得（Place Details API）
- [ ] ユーザーレビューの表示
- [ ] 混雑状況の表示

## 参考リンク

- [Google Places API (New) Documentation](https://developers.google.com/maps/documentation/places/web-service/op-overview)
- [Search Nearby (New) Guide](https://developers.google.com/maps/documentation/places/web-service/search-nearby)
- [Field Mask Guide](https://developers.google.com/maps/documentation/places/web-service/place-data-fields)
- [Pricing Calculator](https://mapsplatform.google.com/pricing/)

