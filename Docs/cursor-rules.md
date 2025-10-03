# Cursor Rules — カフェどこ？ プロジェクト

このドキュメントは Cursor、MCP エージェント、開発者が協調して「カフェどこ？」アプリを開発するための共通ルールをまとめたものです。

## 1. コンテキストの読み込み
- 変更提案の前に必ず `README.md`、`project.yml`、本ファイルを読み込む。
- 特定モジュールを編集する際は関連する Swift ファイルとテストファイルを一緒に参照する。
- `Docs/todo.mcp.json` を確認し、現在のバックログや自動化フックを把握する。

## 2. アーキテクチャ指針
- `App/` は UI の構成とナビゲーションに専念し、ビジネスロジックは `Features/` 以下へ移動する。
- `Features/Core` では `@Observable` や `@Bindable` を用いた状態モデルを公開し、UI 依存を避ける。
- 新機能は機能別モジュール（例: `Features/Schedule`）として追加し、対応するテストを `Tests/` に配置する。
- サービス層（ネットワーク、永続化など）はプロトコルを介した境界を設け、モックを作りやすくする。

## 3. 実装スタイル
- 標準 SDK は iOS 18 をターゲットとし、将来的に iOS 26 に切り替える。可能な限り SwiftUI Observation を使用する。
- 不変なドメインデータには構造体を採用し、共有の状態にのみ `@Observable` クラスを利用する。
- ビュー階層は小さな `private` ビューに分割し、再利用可能な UI は `Features/<Feature>/Views` へ抽出する。
- 非同期処理では async/await を優先し、時間のかかる処理は `Task` ベースの API でラップする。

## 4. テスト規律
- モジュールを変更した場合、必ず関連する `XCTest` の追加または更新を行う。
- スナップショット/UI テストはアセットが固まってから `Tests/AppTests` で `XCTestDynamicOverlay` を活用する計画。
- テスト用フィクスチャは最小限にし、肥大化した場合は `Tests/Support`（必要に応じて作成）へ切り出す。

## 5. Git と MCP ワークフロー
- ブランチ名は `feature/<スコープ>-<概要>` 形式とする。
- コミットは Conventional Commits（`feat:`, `fix:`, `chore:` など）を守り、必要に応じて `Docs/todo.mcp.json` のタスク ID を記載する。
- TODO のステータスは `backlog → in_progress → review → done` の順で更新し、JSON も同じコミットで更新する。
- PR を作成する際は、Cursor に投げた代表的なプロンプトを短くまとめ、必要があれば `Docs/prompts/` に保存する。

## 6. セキュリティと品質ゲート
- 秘密情報はコミットしない。将来的には `xcconfigs` で環境変数を管理する。
- レビュー依頼前に `xcodebuild test -scheme CafeDokoApp -destination "platform=iOS Simulator,name=iPhone 15"` を実行する。
- SwiftFormat / SwiftLint の導入は検討中。導入までは Swift API Design Guidelines に沿った記述を心がける。

## 7. コミュニケーション
- 重要な設計判断は `Docs/adr/ADR-<番号>-<スラッグ>.md` に記録する。
- ブロッカーが発生した場合は MCP TODO の `status` を `blocked` にし、`blocked_by` で依存関係を明示する。
- UI 実装を説明する際は、参考にした iOS26 記事内の該当セクションやリンクを併記する。
