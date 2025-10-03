# Supabase Edge Functions でカフェメニュー自動更新

## 概要

Supabase Edge Functions を使用して、カフェチェーンのメニューと価格情報を自動的に更新します。

## アーキテクチャ

```
┌─────────────────────────────────────────┐
│   Supabase Edge Function (Deno)         │
│   - Cron: 毎週月曜 0:00 JST             │
│   - scrape-cafes/index.ts               │
└────────┬────────────────────────────────┘
         │
         ├──► スクレイピング（各チェーン店）
         │
         └──► Supabase Database
              ├─ chains テーブル
              ├─ chain_products テーブル
              └─ product_sizes テーブル
```

## デプロイ手順

### 1. Supabase CLI のインストール

```bash
# Homebrewでインストール
brew install supabase/tap/supabase

# または npm
npm install -g supabase
```

### 2. Supabase プロジェクトにログイン

```bash
supabase login
```

### 3. プロジェクトをリンク

```bash
cd /Users/asanoyoshiaki/PJ/カフェどこ？
supabase link --project-ref dlwjajmdqopypgzkiwut
```

### 4. Edge Function をデプロイ

```bash
supabase functions deploy scrape-cafes
```

### 5. 環境変数を設定

```bash
# Supabase Dashboard で設定
# Settings → Edge Functions → Environment Variables

SUPABASE_URL=https://dlwjajmdqopypgzkiwut.supabase.co
SUPABASE_SERVICE_ROLE_KEY=<service_role_key>
```

## ローカルでのテスト

### 1. Supabase をローカルで起動

```bash
supabase start
```

### 2. Edge Function をローカル実行

```bash
supabase functions serve scrape-cafes
```

### 3. 関数を呼び出し

```bash
curl -i --location --request POST 'http://localhost:54321/functions/v1/scrape-cafes' \
  --header 'Authorization: Bearer YOUR_ANON_KEY' \
  --header 'Content-Type: application/json'
```

## Cron スケジュール

Edge Function 内で `Deno.cron` を使用:

```typescript
Deno.cron("update-cafe-menus", "0 15 * * 0", async () => {
  // 毎週日曜 15:00 UTC = 月曜 0:00 JST
  console.log("⏰ 定期実行: カフェメニュー更新開始")
  
  const starbucksData = await scrapeStarbucks()
  await saveToSupabase(starbucksData)
})
```

## 監視とログ

### Supabase Dashboard でログ確認

1. Supabase Dashboard にアクセス
2. **Functions** → **scrape-cafes** → **Logs**
3. リアルタイムログとエラーを確認

### ログのフィルタリング

```sql
-- Supabase SQL Editor
SELECT * FROM edge_logs 
WHERE function_name = 'scrape-cafes' 
ORDER BY timestamp DESC 
LIMIT 100;
```

## エラーハンドリング

### 1. スクレイピング失敗時

```typescript
try {
  const data = await scrapeStarbucks()
  await saveToSupabase(data)
} catch (error) {
  console.error('❌ エラー:', error)
  
  // Slack/Discord に通知（オプション）
  await notifyError(error)
  
  // 前回のデータを保持（更新しない）
  return
}
```

### 2. DB保存失敗時

```typescript
const { error } = await supabase.from('chains').upsert(data)

if (error) {
  console.error('DB保存失敗:', error)
  throw new Error(`DB Error: ${error.message}`)
}
```

## コスト

### Supabase Edge Functions の料金

| 項目 | 無料枠 | 超過時の料金 |
|-----|-------|------------|
| 実行回数 | 500,000回/月 | $2 per 100万回 |
| 実行時間 | 400,000秒/月 | $0.000000625 per 秒 |

**週1回の実行:**
- 月4回の実行
- 1回あたり数秒
- **コスト: $0（無料枠内）**

## スクレイピング実装の注意点

### ⚠️ 必ず確認すること

1. **robots.txt の確認**
   ```
   https://example.com/robots.txt
   ```

2. **利用規約の確認**
   - スクレイピングが禁止されていないか
   - 商用利用の可否

3. **アクセス頻度**
   - 過度なリクエストを避ける
   - 間隔を空ける（1秒以上）

4. **User-Agent の設定**
   ```typescript
   const response = await fetch(url, {
     headers: {
       'User-Agent': 'CafeDokoBot/1.0 (+https://cafedoko.app/bot)'
     }
   })
   ```

## 実装例: スターバックス

```typescript
async function scrapeStarbucks(): Promise<Chain> {
  // 1. 公式サイトにアクセス
  const response = await fetch('https://menu.starbucks.co.jp/...')
  const html = await response.text()
  
  // 2. HTMLをパース（Deno DOM使用）
  const doc = new DOMParser().parseFromString(html, 'text/html')
  
  // 3. 商品情報を抽出
  const products = []
  const items = doc.querySelectorAll('.menu-item')
  
  for (const item of items) {
    const name = item.querySelector('.name')?.textContent
    const price = item.querySelector('.price')?.textContent
    
    products.push({
      name,
      category: 'ドリンク',
      sizes: [{ size: 'Tall', price: parseInt(price) }]
    })
  }
  
  return {
    chain_id: 'starbucks',
    chain_name: 'スターバックス',
    products
  }
}
```

## 手動実行

### Supabase Dashboard から

1. **Functions** → **scrape-cafes** → **Invoke Function**
2. Body: `{}`
3. **Invoke** ボタンをクリック

### curl コマンド

```bash
curl -i --location --request POST \
  'https://dlwjajmdqopypgzkiwut.supabase.co/functions/v1/scrape-cafes' \
  --header 'Authorization: Bearer YOUR_ANON_KEY' \
  --header 'Content-Type: application/json'
```

## 拡張機能

### 1. 複数チェーンの対応

```typescript
const chains = [
  scrapeStarbucks,
  scrapeDoutor,
  scrapeTullys,
  scrapeKomeda,
  scrapeExcelsior
]

for (const scraper of chains) {
  const data = await scraper()
  await saveToSupabase(data)
}
```

### 2. 差分検出

```typescript
async function hasChanged(chain: Chain): Promise<boolean> {
  const { data: existing } = await supabase
    .from('chains')
    .select('updated_at')
    .eq('chain_id', chain.chain_id)
    .single()
  
  // 前回の更新から7日以上経過していない場合はスキップ
  if (existing && daysSince(existing.updated_at) < 7) {
    return false
  }
  
  return true
}
```

### 3. Slack/Discord 通知

```typescript
async function notifyUpdate(chain: Chain) {
  const webhookUrl = Deno.env.get('SLACK_WEBHOOK_URL')
  
  await fetch(webhookUrl, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      text: `✅ ${chain.chain_name}のメニューを更新しました`
    })
  })
}
```

## トラブルシューティング

### エラー: `Function not found`

**原因:** デプロイされていない

**解決策:**
```bash
supabase functions deploy scrape-cafes
```

### エラー: `Timeout`

**原因:** 実行時間が長すぎる

**解決策:**
- スクレイピングの並列実行を避ける
- タイムアウト設定を調整

### エラー: `CORS`

**原因:** CORS ヘッダーが正しく設定されていない

**解決策:**
```typescript
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

return new Response(JSON.stringify(data), {
  headers: { ...corsHeaders, 'Content-Type': 'application/json' }
})
```

## 参考リンク

- [Supabase Edge Functions Documentation](https://supabase.com/docs/guides/functions)
- [Deno Cron Documentation](https://deno.com/deploy/docs/cron)
- [Supabase CLI Reference](https://supabase.com/docs/reference/cli/introduction)

