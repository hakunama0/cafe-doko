# Supabase Edge Functions デプロイガイド

## 前提条件

- Supabase アカウント
- Supabase プロジェクト: `dlwjajmdqopypgzkiwut`
- Supabase CLI のインストール

---

## ステップ1: Supabase CLI インストール

### macOS (Homebrew)

```bash
brew install supabase/tap/supabase
```

### または npm

```bash
npm install -g supabase
```

### 確認

```bash
supabase --version
# 出力例: 1.123.4
```

---

## ステップ2: Supabaseにログイン

```bash
supabase login
```

ブラウザが開いてログインを求められます。

---

## ステップ3: プロジェクトをリンク

```bash
cd /Users/asanoyoshiaki/PJ/カフェどこ？
supabase link --project-ref dlwjajmdqopypgzkiwut
```

パスワードを求められた場合は、Supabase のプロジェクトパスワードを入力。

---

## ステップ4: Edge Function をデプロイ

```bash
supabase functions deploy scrape-cafes
```

### 出力例

```
Deploying function scrape-cafes...
✓ Function scrape-cafes deployed successfully
Function URL: https://dlwjajmdqopypgzkiwut.supabase.co/functions/v1/scrape-cafes
```

---

## ステップ5: 環境変数を設定

### Supabase Dashboard で設定

1. https://supabase.com/dashboard/project/dlwjajmdqopypgzkiwut にアクセス
2. **Settings** → **Edge Functions** → **Environment Variables**
3. 以下の変数を追加:

| 変数名 | 値 |
|--------|-----|
| `SUPABASE_URL` | `https://dlwjajmdqopypgzkiwut.supabase.co` |
| `SUPABASE_SERVICE_ROLE_KEY` | Settings → API → service_role key をコピー |

### または CLI で設定

```bash
supabase secrets set SUPABASE_URL=https://dlwjajmdqopypgzkiwut.supabase.co
supabase secrets set SUPABASE_SERVICE_ROLE_KEY=<your_service_role_key>
```

---

## ステップ6: 動作確認

### 手動実行

```bash
curl -i --location --request POST \
  'https://dlwjajmdqopypgzkiwut.supabase.co/functions/v1/scrape-cafes' \
  --header 'Authorization: Bearer <YOUR_ANON_KEY>' \
  --header 'Content-Type: application/json'
```

### または Supabase Dashboard から

1. **Functions** → **scrape-cafes**
2. **Invoke Function** ボタンをクリック
3. Response を確認

### 期待される出力

```json
{
  "success": true,
  "message": "メニュー更新完了",
  "chains": [
    "スターバックス",
    "ドトール",
    "タリーズ",
    "コメダ珈琲",
    "エクセルシオール"
  ],
  "count": 5,
  "timestamp": "2025-10-02T12:00:00.000Z"
}
```

---

## ステップ7: Cron を確認

Edge Function 内の `Deno.cron` は自動的に有効化されます。

```typescript
// supabase/functions/scrape-cafes/index.ts
Deno.cron("update-cafe-menus", "0 15 * * 0", async () => {
  // 毎週日曜 15:00 UTC = 月曜 0:00 JST
  console.log("⏰ 定期実行: カフェメニュー更新開始")
  
  const updatedChains = await updateAllChains()
  console.log(`✅ 定期実行: ${updatedChains.length}チェーンの更新完了`)
})
```

### Cron ログの確認

1. **Functions** → **scrape-cafes** → **Logs**
2. 次回の実行予定: 次の日曜 15:00 UTC（月曜 0:00 JST）

---

## トラブルシューティング

### エラー: `supabase: command not found`

**原因:** CLI がインストールされていない

**解決策:**
```bash
brew install supabase/tap/supabase
```

---

### エラー: `Project not linked`

**原因:** プロジェクトがリンクされていない

**解決策:**
```bash
supabase link --project-ref dlwjajmdqopypgzkiwut
```

---

### エラー: `Function deployment failed`

**原因:** 構文エラーまたは依存関係の問題

**解決策:**
```bash
# ローカルでテスト
supabase functions serve scrape-cafes

# 別のターミナルで実行
curl http://localhost:54321/functions/v1/scrape-cafes
```

---

### エラー: `SUPABASE_SERVICE_ROLE_KEY is not defined`

**原因:** 環境変数が設定されていない

**解決策:**
1. Supabase Dashboard → Settings → API
2. `service_role` key をコピー
3. Edge Functions → Environment Variables で設定

---

## 運用

### ログの確認

```bash
# リアルタイムログ
supabase functions logs scrape-cafes

# または Dashboard
# Functions → scrape-cafes → Logs
```

### 再デプロイ

コードを更新したら:

```bash
supabase functions deploy scrape-cafes
```

### 削除

```bash
supabase functions delete scrape-cafes
```

---

## まとめ

1. ✅ Supabase CLI インストール
2. ✅ `supabase login`
3. ✅ `supabase link --project-ref dlwjajmdqopypgzkiwut`
4. ✅ `supabase functions deploy scrape-cafes`
5. ✅ 環境変数を設定
6. ✅ 動作確認
7. ✅ Cron が自動実行されることを確認

これで毎週月曜 0:00 JST に自動でメニュー更新が実行されます！

