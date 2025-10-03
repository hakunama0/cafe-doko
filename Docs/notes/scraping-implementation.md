# カフェメニュー スクレイピング実装ガイド

## 概要

5大カフェチェーン（スターバックス、ドトール、タリーズ、コメダ珈琲、エクセルシオール）のメニュー・価格情報を自動取得するスクレイパー実装。

## 実装ファイル

### 1. `Scripts/scrape_all_chains.py`

**5社一括スクレイパー**

```python
python3 Scripts/scrape_all_chains.py
```

**出力:**
- `Resources/ChainsMenu.json` を更新
- 各チェーンのメニュー・価格情報を統合

**スクレイパークラス:**
- `StarbucksScraper`: スターバックス
- `DoutorScraper`: ドトール
- `TullysScraper`: タリーズ
- `KomedaScraper`: コメダ珈琲
- `ExcelsiorScraper`: エクセルシオール

### 2. `Scripts/scrape_starbucks.py`

**スターバックス単体スクレイパー（デバッグ用）**

```python
python3 Scripts/scrape_starbucks.py
```

## データ構造

### ChainsMenu.json

```json
{
  "chains": [
    {
      "id": "starbucks",
      "name": "スターバックス",
      "categories": [
        {
          "name": "ドリンク",
          "products": [
            {
              "name": "ドリップコーヒー",
              "category": "ドリンク",
              "sizes": [
                {"size": "Short", "price": 390},
                {"size": "Tall", "price": 430},
                {"size": "Grande", "price": 470},
                {"size": "Venti", "price": 510}
              ]
            }
          ]
        }
      ]
    }
  ],
  "last_updated": "2025-10-02 12:00:00"
}
```

## スクレイピング戦略

### 現在の実装（フォールバック）

各チェーンのデフォルトメニューを定義し、スクレイピング失敗時に使用。

**メリット:**
- ✅ 確実にデータが取得できる
- ✅ ネットワークエラーに強い
- ✅ 公式サイトの変更に影響されない

**デメリット:**
- ⚠️ 価格変更に追従できない
- ⚠️ 新商品が反映されない

### 実際のスクレイピング実装（TODO）

各チェーンの公式サイトから情報を取得。

```python
def scrape_starbucks_real() -> Dict:
    url = "https://menu.starbucks.co.jp/..."
    response = requests.get(url, headers=headers)
    soup = BeautifulSoup(response.content, 'html.parser')
    
    # 商品リストを取得
    items = soup.select('.product-item')
    
    products = []
    for item in items:
        name = item.select_one('.product-name').text
        prices = item.select('.price')
        
        # サイズと価格を抽出
        sizes = []
        for idx, price_elem in enumerate(prices):
            price = extract_price(price_elem.text)
            size = ['Short', 'Tall', 'Grande', 'Venti'][idx]
            sizes.append({"size": size, "price": price})
        
        products.append({
            "name": name,
            "category": "ドリンク",
            "sizes": sizes
        })
    
    return format_data("starbucks", "スターバックス", products)
```

## 各チェーンの実装状況

| チェーン | 実装状態 | 商品数 | 備考 |
|---------|---------|-------|------|
| スターバックス | ✅ フォールバック | 5商品 | Short/Tall/Grande/Venti |
| ドトール | ✅ フォールバック | 6商品 | S/M サイズ |
| タリーズ | ✅ フォールバック | 5商品 | Short/Tall/Grande |
| コメダ珈琲 | ✅ フォールバック | 7商品 | M サイズのみ |
| エクセルシオール | ✅ フォールバック | 6商品 | S/M/L サイズ |

## 自動化

### GitHub Actions

```yaml
# .github/workflows/scrape-menus.yml
name: Update Cafe Menus

on:
  schedule:
    - cron: '0 15 * * 0'  # 毎週月曜 0:00 JST
  workflow_dispatch:

jobs:
  scrape-and-update:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
      - run: pip install -r Scripts/requirements.txt
      - run: python3 Scripts/scrape_all_chains.py
      - run: python3 Scripts/import_chains_to_supabase.py
```

### Supabase Edge Functions

```typescript
// supabase/functions/scrape-cafes/index.ts
Deno.cron("update-cafe-menus", "0 15 * * 0", async () => {
  const chains = [
    await scrapeStarbucks(),
    await scrapeDoutor(),
    await scrapeTullys(),
    await scrapeKomeda(),
    await scrapeExcelsior()
  ]
  
  for (const chain of chains) {
    await saveToSupabase(chain)
  }
})
```

## 実際のスクレイピング実装ガイド

### ⚠️ 事前確認事項

1. **robots.txt を確認**
   ```
   https://example.com/robots.txt
   ```

2. **利用規約を確認**
   - スクレイピングが禁止されていないか
   - 商用利用の可否

3. **公式APIの有無を確認**
   - APIが提供されている場合は必ずそちらを使用

### 実装手順

#### 1. ターゲットページを特定

各チェーンのメニューページを確認:

- **スターバックス**: https://menu.starbucks.co.jp/
- **ドトール**: https://www.doutor.co.jp/menu/
- **タリーズ**: https://www.tullys.co.jp/menu/
- **コメダ珈琲**: https://www.komeda.co.jp/menu/
- **エクセルシオール**: https://www.excelsior-caffe.co.jp/menu/

#### 2. HTML構造を解析

Chrome DevTools で要素を調査:

```html
<!-- 例: スターバックス -->
<div class="product-item">
  <h3 class="product-name">ドリップコーヒー</h3>
  <div class="prices">
    <span class="price" data-size="Short">¥390</span>
    <span class="price" data-size="Tall">¥430</span>
    <span class="price" data-size="Grande">¥470</span>
    <span class="price" data-size="Venti">¥510</span>
  </div>
</div>
```

#### 3. セレクタを特定

```python
soup = BeautifulSoup(html, 'html.parser')

# 商品リスト
items = soup.select('.product-item')

# 各商品の情報
for item in items:
    name = item.select_one('.product-name').text
    prices = item.select('.price')
```

#### 4. データ抽出ロジック実装

```python
def extract_product(item) -> Product:
    """商品情報を抽出"""
    name = item.select_one('.product-name').get_text(strip=True)
    category = item.get('data-category', 'ドリンク')
    
    sizes = []
    for price_elem in item.select('.price'):
        size = price_elem.get('data-size', 'M')
        price_text = price_elem.get_text(strip=True)
        price = int(''.join(filter(str.isdigit, price_text)))
        
        sizes.append({
            "size": size,
            "price": price
        })
    
    return {
        "name": name,
        "category": category,
        "sizes": sizes
    }
```

#### 5. エラーハンドリング

```python
def scrape_with_fallback(scraper_func, default_data):
    """スクレイピング実行（フォールバック付き）"""
    try:
        return scraper_func()
    except requests.RequestException as e:
        print(f"⚠️ ネットワークエラー: {e}")
        return default_data
    except Exception as e:
        print(f"⚠️ 解析エラー: {e}")
        return default_data
```

#### 6. レート制限

```python
import time

for scraper in scrapers:
    data = scraper.scrape()
    # 各リクエスト間で1秒待機
    time.sleep(1)
```

## テスト

### ローカルテスト

```bash
# 5社一括実行
python3 Scripts/scrape_all_chains.py

# スターバックス単体
python3 Scripts/scrape_starbucks.py

# 結果確認
cat Resources/ChainsMenu.json | jq '.chains[] | {id, name, product_count: .categories[].products | length}'
```

### 出力例

```json
{
  "id": "starbucks",
  "name": "スターバックス",
  "product_count": 5
}
{
  "id": "doutor",
  "name": "ドトール",
  "product_count": 6
}
```

## 運用

### 定期実行

**GitHub Actions:**
- 週次実行（毎週月曜 0:00 JST）
- 自動コミット & プッシュ

**Supabase Edge Functions:**
- Deno.cron で週次実行
- 直接DBに保存

### 監視

```bash
# ログ確認（GitHub Actions）
gh run list --workflow scrape-menus.yml

# ログ確認（Supabase）
# Supabase Dashboard → Functions → scrape-cafes → Logs
```

### アラート

```python
def notify_slack(message: str):
    """Slackに通知"""
    webhook_url = os.getenv('SLACK_WEBHOOK_URL')
    requests.post(webhook_url, json={"text": message})

# 使用例
if error:
    notify_slack(f"⚠️ スクレイピング失敗: {error}")
```

## 今後の改善

- [ ] 実際のスクレイピングロジック実装
- [ ] 価格変動の検出と通知
- [ ] 新商品の自動検出
- [ ] 画像URLの取得
- [ ] 栄養情報の取得
- [ ] 季節限定商品のフラグ付け
- [ ] 地域別価格の対応

## 参考リンク

- [Beautiful Soup Documentation](https://www.crummy.com/software/BeautifulSoup/bs4/doc/)
- [Requests Documentation](https://requests.readthedocs.io/)
- [robots.txt 解説](https://developers.google.com/search/docs/crawling-indexing/robots/intro)

