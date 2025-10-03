# カフェメニュー情報の自動更新

## 概要

カフェチェーンのメニューと価格情報を定期的に自動更新するためのシステム。

## アーキテクチャ

```
┌─────────────────┐
│ GitHub Actions  │  週1回実行（毎週月曜 0:00 JST）
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Scraper Script │  各チェーン店の公式サイトから情報取得
│  (Python)       │
└────────┬────────┘
         │
         ├──► Resources/ChainsMenu.json (ローカルDB)
         │
         └──► Supabase (クラウドDB)
              ├─ chains テーブル
              ├─ chain_products テーブル
              └─ product_sizes テーブル
```

## 実装方法

### 1. GitHub Actions (推奨)

**メリット:**
- 無料（パブリックリポジトリ）
- 設定が簡単
- Git履歴で変更を追跡可能

**設定:**
`.github/workflows/scrape-menus.yml` で自動実行を設定。

```yaml
on:
  schedule:
    - cron: '0 15 * * 0'  # 毎週日曜 15:00 UTC = 月曜 0:00 JST
  workflow_dispatch:       # 手動実行も可能
```

**必要なシークレット:**
- `SUPABASE_KEY`: Supabase の anon/service key

### 2. Supabase Edge Functions

**メリット:**
- Supabase内で完結
- 低レイテンシ
- 直接DBに書き込み可能

**実装例:**
```typescript
// supabase/functions/update-menus/index.ts
Deno.cron("update-menus", "0 0 * * 1", async () => {
  const data = await scrapeStarbucks();
  await supabase.from('chain_products').upsert(data);
});
```

### 3. AWS Lambda + EventBridge

**メリット:**
- スケーラブル
- 他のAWSサービスとの統合

**コスト:**
- 週1回実行なら無料枠内

## スクレイピング実装

### 注意事項

⚠️ **必ず以下を確認してください:**

1. **robots.txt の確認**
   ```
   https://example.com/robots.txt
   ```

2. **利用規約の確認**
   - スクレイピングが禁止されていないか
   - 商用利用の可否

3. **API の優先**
   - 公式APIがある場合は必ずそちらを使用

4. **アクセス頻度**
   - 過度なリクエストを避ける
   - 間隔を空ける（例: 1秒以上）

5. **User-Agent の設定**
   ```python
   headers = {
       'User-Agent': 'CafeDokoBot/1.0 (+https://cafedoko.app/bot)'
   }
   ```

### 実装例

```python
import requests
from bs4 import BeautifulSoup
import time

def scrape_chain_menu(url: str) -> dict:
    """
    カフェチェーンのメニュー情報を取得
    """
    headers = {
        'User-Agent': 'CafeDokoBot/1.0 (+https://cafedoko.app/bot)'
    }
    
    response = requests.get(url, headers=headers)
    response.raise_for_status()
    
    soup = BeautifulSoup(response.content, 'html.parser')
    
    # サイト構造に応じてパース
    products = []
    for item in soup.select('.menu-item'):
        name = item.select_one('.name').text.strip()
        price = item.select_one('.price').text.strip()
        products.append({
            'name': name,
            'price': int(price.replace('円', '').replace(',', ''))
        })
    
    time.sleep(1)  # 次のリクエストまで待機
    
    return {'products': products}
```

## 各チェーンの対応状況

| チェーン | スクレイピング | 公式API | 更新頻度 | 実装状況 |
|---------|--------------|---------|---------|---------|
| スターバックス | ⚠️ 要確認 | ❌ なし | 月1回程度 | 🚧 準備中 |
| ドトール | ⚠️ 要確認 | ❌ なし | 年2回程度 | 📝 計画中 |
| タリーズ | ⚠️ 要確認 | ❌ なし | 月1回程度 | 📝 計画中 |
| コメダ | ⚠️ 要確認 | ❌ なし | 年2回程度 | 📝 計画中 |
| エクセルシオール | ⚠️ 要確認 | ❌ なし | 月1回程度 | 📝 計画中 |

## 代替案: 手動更新 + コミュニティ貢献

スクレイピングが難しい場合:

1. **月1回の手動更新**
   - チーム/個人で公式サイトを確認
   - `ChainsMenu.json` を更新

2. **コミュニティ貢献**
   - ユーザーからの情報提供を受け付け
   - Pull Request で更新

3. **店舗からの情報提供**
   - 各チェーンに協力を依頼
   - 公式データの提供を受ける

## 監視とアラート

### GitHub Actions の監視

- 失敗時に通知（Slack, Discord, メール）
- 週次レポートの自動生成

### データ品質チェック

```python
def validate_menu_data(data: dict) -> bool:
    """
    更新されたデータの妥当性を検証
    """
    if not data.get('chains'):
        return False
    
    for chain in data['chains']:
        if not chain.get('name') or not chain.get('categories'):
            return False
        
        # 価格が異常値でないかチェック
        for category in chain['categories']:
            for product in category['products']:
                for size in product['sizes']:
                    price = size.get('price', 0)
                    if price < 100 or price > 2000:
                        print(f"⚠️ 異常価格検出: {product['name']} - {price}円")
                        return False
    
    return True
```

## 今後の拡張

- [ ] 全チェーンのスクレイピング実装
- [ ] 価格変動の通知機能
- [ ] 新商品の自動検出
- [ ] 季節限定商品のフラグ
- [ ] 地域別価格の対応
- [ ] 画像の自動取得
- [ ] 栄養情報の追加

## 参考リンク

- [GitHub Actions - Schedule](https://docs.github.com/en/actions/using-workflows/events-that-trigger-workflows#schedule)
- [Supabase Edge Functions](https://supabase.com/docs/guides/functions)
- [Beautiful Soup Documentation](https://www.crummy.com/software/BeautifulSoup/bs4/doc/)
- [Scrapy Framework](https://scrapy.org/)

