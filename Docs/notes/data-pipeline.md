# データ取得パイプラインメモ

- MVP では `CafeMockData.json` をバンドルに含め、`LocalJSONCafeDataProvider` が同期的に読み込む。
- 将来的に API 化する場合は `CafeDataProviding` を HTTP 実装へ差し替えるだけで運用可能。
- 画像は `CafeImageProviding` で抽象化し、現在は SF Symbols ベースの `SymbolCafeImageProvider` を利用。
- `DokoCafeViewModel` ではロード状態（`isLoading`／`lastErrorMessage`）を公開し、SwiftUI 側でプログレス表示やエラーバナーを制御する。

## 設定ファイル
- `Config/cafe-doko-config.json` で `mock` / `remote` の切り替えを行う。
- `remote` 指定時は `url` とヘッダーを設定し、API キーなどはビルド設定から注入する。
- 設定ファイルがない場合はモック JSON が自動読み込みされる。
