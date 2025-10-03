# ADR-001: モジュラーアーキテクチャの採用

- **タイトル**: Swift Package Manager ベースのモジュラーアーキテクチャ採用
- **日付**: 2025-02-02
- **ステータス**: 承認済み
- **関連タスク**: APP-001, DC-001

## コンテキスト

「カフェどこ？」プロジェクトでは、以下の要件を満たす必要がある：

- 複数の機能を並行開発できる構造
- 各機能モジュールの独立したテスト実行
- UI コンポーネントの再利用性向上
- ビルド時間の最適化（増分ビルド対応）
- AI エージェント（Cursor）との協調開発において、モジュール境界を明確化

従来のモノリシックな構成では、以下の課題があった：

- 全ファイルが単一ターゲットに含まれ、依存関係が不明瞭
- テスト実行時に関係ないコードもコンパイルされる
- 機能追加時にファイル配置の一貫性が保てない

## 決定

### 採用するアプローチ

XcodeGen + Swift Package Manager（ローカルパッケージ）を用いたモジュラーアーキテクチャを採用する。

**プロジェクト構成**:

```
カフェどこ？/
├── App/                    # アプリケーションエントリポイント
│   ├── CafeDokoApp.swift
│   └── ContentView.swift
├── Features/
│   ├── Core/              # 共通基盤モジュール
│   │   ├── Sources/
│   │   │   ├── AppStateModel.swift
│   │   │   └── MCPBridge.swift
│   │   └── Tests/
│   └── DokoCafe/          # カフェ機能モジュール
│       ├── Sources/
│       │   ├── DokoCafeFeature.swift
│       │   ├── CafeProviders.swift
│       │   └── CafeConfigurator.swift
│       └── Tests/
├── Resources/             # 共有リソース
└── project.yml            # XcodeGen 設定
```

**モジュール境界**:

1. **App シェル** - UI ルートとアプリ初期化のみ
2. **Core** - 共通データモデル、ユーティリティ、MCP Bridge
3. **DokoCafe** - カフェ検索機能（ViewModel、Provider、Configurator）

### 代替案と選択理由

**代替案 1: モノリシック構成**
- ❌ テストの実行速度が遅い
- ❌ 依存関係が不明瞭
- ✅ シンプル

**代替案 2: Swift Package Manager のみ（外部パッケージ化）**
- ❌ Xcode プロジェクトとの統合が煩雑
- ❌ リソース管理が複雑
- ✅ 完全な独立性

**採用案: XcodeGen + ローカル SPM**
- ✅ Xcode プロジェクトを `project.yml` から自動生成
- ✅ 各モジュールがフレームワークとしてビルド
- ✅ リソースの共有が容易
- ✅ 増分ビルドによる高速化
- ✅ モジュール間の依存関係を明示的に定義

## 決定の理由

1. **開発速度の向上**
   - 変更したモジュールのみ再ビルド
   - 機能ごとにテストを分離実行可能

2. **コードの再利用性**
   - `Core` モジュールを将来の他機能から参照可能
   - `DokoCafe` を独立モジュールとして他アプリへ移植可能

3. **AI エージェントとの協調**
   - Cursor が各モジュールの責務を理解しやすい
   - ファイル検索範囲をモジュール単位で絞り込める

4. **保守性の向上**
   - 依存方向が明確（App → DokoCafe → Core）
   - 循環依存を防止

## 影響

### コードベースへの影響

- **プラス影響**:
  - 新機能追加時は `Features/` 配下に新モジュールを追加するだけ
  - テストファイルが機能ごとに整理される
  - import 文で依存関係が可視化される

- **マイナス影響**:
  - プロジェクト初期セットアップに XcodeGen が必要
  - モジュール分割の粒度判断が必要

### テストへの影響

- 各モジュールのテストを独立実行可能：
  ```bash
  xcodebuild test -scheme CafeDokoCore
  xcodebuild test -scheme DokoCafeFeature
  ```
- テストターゲットがモジュールごとに自動生成される

### 運用への の影響

- `project.yml` 編集後に `xcodegen generate` を実行
- `.xcodeproj` ファイルは Git 管理から除外可能（オプション）
- CI/CD では XcodeGen インストールが必要

### フォローアップタスク

- [x] XcodeGen で初期プロジェクト生成（APP-001）
- [x] Core モジュールの基本実装（AppStateModel）
- [x] DokoCafe モジュールの実装（DC-001）
- [x] MCP Bridge を Core に追加（APP-002）
- [ ] 将来: Auth, Schedule 等の機能モジュール追加

## 参考資料

- [XcodeGen 公式ドキュメント](https://github.com/yonaskolb/XcodeGen)
- [Swift Package Manager - Apple Developer](https://developer.apple.com/documentation/swift-packages)
- [Modular Architecture - objc.io](https://www.objc.io/issues/22-scale/modular-architecture/)
- プロジェクト内: `project.yml`, `Docs/cursor-rules.md`

## 備考

このアーキテクチャは MVP（Minimum Viable Product）段階に最適化されている。
プロジェクト規模が拡大した場合は、以下の検討が必要：

- ネットワーク層の分離（Networking モジュール）
- UI コンポーネントライブラリの独立（DesignSystem モジュール）
- 機能フラグ管理の導入（FeatureFlags モジュール）

これらの変更は ADR-00X として別途記録する予定。

