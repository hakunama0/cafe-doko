# MCP CLI Tool

MCP (Model Context Protocol) と連携してタスク管理を行う CLI ツールです。

## 使い方

### タスク一覧の表示

```bash
# すべてのタスクを表示
swift Tools/mcp-cli/main.swift list

# 特定のステータスでフィルタ
swift Tools/mcp-cli/main.swift list --status=in_progress
swift Tools/mcp-cli/main.swift list --status=blocked
```

### タスク詳細の表示

```bash
swift Tools/mcp-cli/main.swift show DC-001
```

### タスクステータスの更新

```bash
swift Tools/mcp-cli/main.swift update DC-001 in_progress
swift Tools/mcp-cli/main.swift update DC-002 done
```

### MCP ホストとの同期（開発中）

```bash
swift Tools/mcp-cli/main.swift sync
```

## ステータス一覧

- `backlog` - 未着手
- `in_progress` - 進行中
- `review` - レビュー中
- `blocked` - ブロック中
- `done` - 完了

## エイリアスの設定（オプション）

頻繁に使う場合は、シェルにエイリアスを追加すると便利です：

```bash
# ~/.zshrc または ~/.bashrc に追加
alias mcp='swift Tools/mcp-cli/main.swift'

# 使用例
mcp list
mcp show DC-001
mcp update DC-001 done
```

## 開発

MCP Bridge のコア機能は `Features/Core/Sources/MCPBridge.swift` に実装されています。
テストは `Features/Core/Tests/MCPBridgeTests.swift` にあります。

```bash
# テストの実行
xcodebuild test -scheme CafeDokoCore -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6'
```

## TODO

- [ ] MCP ホストプロトコルとの実際の同期機能
- [ ] GitHub Issues との双方向同期
- [ ] タスク作成機能の追加
- [ ] タスク削除機能の追加
- [ ] 進捗レポート生成機能

