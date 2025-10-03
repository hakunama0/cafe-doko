# ADR-002: Model Context Protocol (MCP) 統合

- **タイトル**: MCP による AI エージェント協調開発基盤の構築
- **日付**: 2025-02-02
- **ステータス**: 承認済み
- **関連タスク**: APP-002, DOC-001

## コンテキスト

「カフェどこ？」プロジェクトでは、Cursor などの AI エージェントと協調して開発を進めることが前提となっている。以下の課題があった：

- タスク管理が口頭指示やメモリ依存で、状態が不明瞭
- AI エージェントがプロジェクトの進捗状況を把握しにくい
- タスクの依存関係やブロック状態が可視化されていない
- 複数セッションにまたがると、コンテキストが失われる

従来の GitHub Issues や Linear などの外部ツールでは：

- API 連携が煩雑で、リアルタイム同期が難しい
- AI エージェントが直接アクセスできない
- オフライン開発時に使えない

## 決定

### 採用するアプローチ

**Model Context Protocol (MCP) 準拠の TODO 管理システム**を構築する。

**実装内容**:

1. **todo.mcp.json** - タスク定義ファイル
   - プロジェクト情報、ワークフロー、タスク一覧を JSON 形式で管理
   - Git でバージョン管理
   - AI エージェントが直接読み書き可能

2. **MCPBridge モジュール** (`Features/Core/Sources/MCPBridge.swift`)
   - `todo.mcp.json` の読み込み/保存
   - タスクのフィルタリング（ステータス、オーナー、ブロック状態）
   - タスクステータスの更新

3. **CLI ツール** (`Tools/mcp-cli/main.swift`)
   - タスク一覧表示: `swift Tools/mcp-cli/main.swift list`
   - タスク詳細表示: `swift Tools/mcp-cli/main.swift show <task-id>`
   - ステータス更新: `swift Tools/mcp-cli/main.swift update <task-id> <status>`

4. **ワークフロー定義**
   ```
   backlog → in_progress → review → done
              ↓
           blocked
   ```

### 代替案と選択理由

**代替案 1: GitHub Issues**
- ✅ 外部ツールとの統合が容易
- ❌ API レート制限がある
- ❌ オフライン作業ができない
- ❌ AI エージェントの直接操作が困難

**代替案 2: Linear / Jira**
- ✅ 高機能なプロジェクト管理
- ❌ 外部サービス依存
- ❌ API 認証が必要
- ❌ 学習コストが高い

**代替案 3: Markdown チェックリスト**
- ✅ シンプル
- ❌ 構造化されていない
- ❌ プログラマティックな操作が困難
- ❌ フィルタリングや集計ができない

**採用案: MCP 準拠の JSON ベース管理**
- ✅ Git でバージョン管理
- ✅ オフライン作業可能
- ✅ AI エージェントが直接操作可能
- ✅ CLI ツールで人間も操作可能
- ✅ 構造化されたデータで集計・分析が容易
- ✅ 将来的に外部ツールとの同期も可能

## 決定の理由

1. **AI エージェントとの協調**
   - Cursor が `Docs/todo.mcp.json` を直接読んでタスク状況を把握
   - エージェントがタスクステータスを更新可能
   - プロンプト内でタスク ID を参照して作業範囲を明確化

2. **透明性とトレーサビリティ**
   - すべてのタスク変更が Git コミットとして記録
   - レビュー時に変更履歴を確認可能
   - ブランチごとに異なるタスクセットを管理可能

3. **開発速度の向上**
   - CLI ツールで即座にタスク状況を確認
   - ブロック状態や依存関係を可視化
   - 進捗レポートの自動生成が可能

4. **柔軟性**
   - JSON 形式なので他言語・ツールからも操作可能
   - 将来的に GitHub Issues や Linear と双方向同期可能
   - カスタムワークフローやフィールドの追加が容易

## 影響

### コードベースへの影響

- **追加されたコンポーネント**:
  - `Features/Core/Sources/MCPBridge.swift` - MCP ブリッジモジュール
  - `Features/Core/Tests/MCPBridgeTests.swift` - ユニットテスト
  - `Tools/mcp-cli/main.swift` - CLI ツール
  - `Docs/todo.mcp.json` - タスク定義ファイル
  - `Docs/mcp-workflow.md` - ワークフロー手順書

- **開発フロー**:
  ```bash
  # タスク確認
  swift Tools/mcp-cli/main.swift list --status=in_progress
  
  # 作業開始
  swift Tools/mcp-cli/main.swift update DC-002 in_progress
  
  # 実装 & テスト
  
  # レビュー準備
  swift Tools/mcp-cli/main.swift update DC-002 review
  git add -A
  git commit -m "feat: DC-002 実装完了"
  ```

### チーム開発への影響

- **プラス影響**:
  - AI エージェントと人間が同じタスクリストを参照
  - タスクの割り当てや進捗が明確
  - ブロッカーの早期発見

- **学習コスト**:
  - MCP CLI の使い方（5分程度）
  - JSON 形式の理解（基本的な構造のみ）

### 運用への影響

- **CI/CD**:
  - `todo.mcp.json` の妥当性検証を追加可能
  - タスクステータスと PR 状態の整合性チェック

- **メトリクス**:
  - タスク完了率、サイクルタイム等の自動集計
  - ブロック頻度の可視化

### フォローアップタスク

- [x] MCPBridge モジュール実装（APP-002）
- [x] CLI ツール実装（APP-002）
- [x] ユニットテスト追加（APP-002）
- [ ] MCP ホストプロトコルとの実際の同期（将来）
- [ ] GitHub Issues との双方向同期（将来）
- [ ] 進捗レポート自動生成機能（将来）
- [ ] VS Code Extension の開発（将来）

## 参考資料

- [Model Context Protocol - Anthropic](https://www.anthropic.com/news/model-context-protocol)
- Cursor Rules: `Docs/cursor-rules.md`
- MCP ワークフロー: `Docs/mcp-workflow.md`
- JSON Schema 仕様（将来追加予定）

## 実装詳細

### todo.mcp.json の構造

```json
{
  "project": "カフェどこ？",
  "version": "0.1.0",
  "updated_at": "2025-02-02T00:00:00Z",
  "owners": ["asanaoyoshiaki", "cursor"],
  "workflow": ["backlog", "in_progress", "review", "blocked", "done"],
  "tasks": [
    {
      "id": "DC-001",
      "title": "どこカフェ？機能のモジュール骨格を追加",
      "status": "done",
      "owner": "cursor",
      "description": "...",
      "links": ["Features/DokoCafe/..."],
      "notes": ["..."],
      "tags": ["dokocafe", "architecture"],
      "blocked_by": [],
      "due_date": "2025-02-18"
    }
  ]
}
```

### MCPBridge API

```swift
let bridge = MCPBridge()

// タスク読み込み
let document = try bridge.loadTasks()

// フィルタリング
let inProgressTasks = bridge.tasks(withStatus: .inProgress, from: document)
let blockedTasks = bridge.blockedTasks(from: document)

// ステータス更新
var doc = try bridge.loadTasks()
try bridge.updateTaskStatus(taskId: "DC-001", newStatus: .done, in: &doc)
try bridge.saveTasks(doc)
```

## セキュリティ考慮事項

- **機密情報の扱い**:
  - API キーや認証情報は `todo.mcp.json` に含めない
  - パスワードや個人情報も記載禁止
  - 必要な場合は `Config/.secrets/secrets.env` を使用

- **アクセス制御**:
  - `todo.mcp.json` は Git で管理されるため、リポジトリアクセス権と同等
  - パブリックリポジトリでは公開されることを前提に記述

## 備考

MCP 統合は段階的に進化させる予定：

**Phase 1（完了）**: ローカル JSON ベースの管理
- CLI ツールによる操作
- AI エージェントとの協調

**Phase 2（計画中）**: リアルタイム同期
- MCP ホストプロトコルとの統合
- Cursor との双方向通信

**Phase 3（将来）**: 外部ツール統合
- GitHub Issues との同期
- Slack/Discord 通知
- ダッシュボード UI

各フェーズの実装は別途 ADR で記録する。

