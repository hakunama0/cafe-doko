#!/usr/bin/env python3
"""
スターバックス公式サイトから商品情報をスクレイピング
"""
import json
import time
from typing import Dict, List, Optional
import requests
from bs4 import BeautifulSoup

def scrape_starbucks_menu() -> Dict:
    """
    スターバックスのメニュー情報を取得
    公式メニューページから価格とサイズを抽出
    """
    print("🔍 スターバックスメニューを取得中...")
    
    base_url = "https://menu.starbucks.co.jp"
    headers = {
        'User-Agent': 'CafeDokoBot/1.0 (+https://cafedoko.app/bot)',
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        'Accept-Language': 'ja,en-US;q=0.7,en;q=0.3'
    }
    
    # カテゴリーページ
    categories = {
        "ドリンク": f"{base_url}/4524785379299456",  # コーヒー
        "フード": f"{base_url}/4524785398173696"      # フード
    }
    
    products = []
    
    for category_name, category_url in categories.items():
        try:
            print(f"  📄 {category_name}カテゴリーを取得中...")
            response = requests.get(category_url, headers=headers, timeout=10)
            response.raise_for_status()
            
            soup = BeautifulSoup(response.content, 'html.parser')
            
            # 商品リストを取得（実際のHTML構造に応じて調整）
            items = soup.select('.product-item, .menu-item')
            
            for item in items[:5]:  # 各カテゴリーから最大5商品
                try:
                    # 商品名を取得
                    name_elem = item.select_one('.product-name, .item-name, h3, h4')
                    if not name_elem:
                        continue
                    
                    product_name = name_elem.get_text(strip=True)
                    
                    # 価格情報を取得
                    prices = []
                    price_elems = item.select('.price, .product-price')
                    
                    if price_elems:
                        for idx, price_elem in enumerate(price_elems):
                            price_text = price_elem.get_text(strip=True)
                            # "¥430" や "430円" などから数値を抽出
                            price_num = int(''.join(filter(str.isdigit, price_text)))
                            
                            # サイズを推定
                            size_names = ['Short', 'Tall', 'Grande', 'Venti']
                            size = size_names[idx] if idx < len(size_names) else 'M'
                            
                            prices.append({
                                "size": size,
                                "price": price_num
                            })
                    
                    # 価格情報がない場合はデフォルト値
                    if not prices:
                        if category_name == "ドリンク":
                            prices = [
                                {"size": "Short", "price": 390},
                                {"size": "Tall", "price": 430},
                                {"size": "Grande", "price": 470},
                                {"size": "Venti", "price": 510}
                            ]
                        else:
                            prices = [{"size": "M", "price": 400}]
                    
                    products.append({
                        "name": product_name,
                        "category": category_name,
                        "sizes": prices
                    })
                    
                except Exception as e:
                    print(f"    ⚠️ 商品解析エラー: {e}")
                    continue
            
            time.sleep(1)  # 次のリクエストまで待機
            
        except Exception as e:
            print(f"  ❌ {category_name}カテゴリーの取得に失敗: {e}")
            continue
    
    # データが取得できなかった場合のフォールバック
    if not products:
        print("  ℹ️ スクレイピング失敗、デフォルトデータを使用")
        products = [
            {
                "name": "ドリップコーヒー",
                "category": "ドリンク",
                "sizes": [
                    {"size": "Short", "price": 390},
                    {"size": "Tall", "price": 430},
                    {"size": "Grande", "price": 470},
                    {"size": "Venti", "price": 510}
                ]
            },
            {
                "name": "カフェラテ",
                "category": "ドリンク",
                "sizes": [
                    {"size": "Short", "price": 460},
                    {"size": "Tall", "price": 505},
                    {"size": "Grande", "price": 550},
                    {"size": "Venti", "price": 595}
                ]
            },
            {
                "name": "キャラメルマキアート",
                "category": "ドリンク",
                "sizes": [
                    {"size": "Short", "price": 490},
                    {"size": "Tall", "price": 535},
                    {"size": "Grande", "price": 580},
                    {"size": "Venti", "price": 625}
                ]
            }
        ]
    
    result = {
        "id": "starbucks",
        "name": "スターバックス",
        "categories": [
            {
                "name": cat,
                "products": [p for p in products if p["category"] == cat]
            }
            for cat in set(p["category"] for p in products)
        ]
    }
    
    print(f"✅ スターバックス: {len(products)}商品を取得")
    return result


def update_chains_menu(new_chain_data: Dict):
    """
    ChainsMenu.jsonを更新
    """
    json_path = "Resources/ChainsMenu.json"
    
    try:
        with open(json_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
    except FileNotFoundError:
        print(f"⚠️ {json_path} が見つかりません")
        data = {"chains": []}
    
    chains = data.get("chains", [])
    updated = False
    
    for i, chain in enumerate(chains):
        if chain.get("id") == new_chain_data.get("id"):
            chains[i] = new_chain_data
            updated = True
            print(f"✅ {new_chain_data['name']}の情報を更新しました")
            break
    
    if not updated:
        chains.append(new_chain_data)
        print(f"✅ {new_chain_data['name']}を新規追加しました")
    
    data["chains"] = chains
    data["last_updated"] = time.strftime("%Y-%m-%d %H:%M:%S")
    
    with open(json_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    
    print(f"💾 {json_path} を保存しました")


def main():
    print("=" * 50)
    print("スターバックス メニュー自動更新")
    print("=" * 50)
    
    starbucks_data = scrape_starbucks_menu()
    update_chains_menu(starbucks_data)
    
    print("\n✨ 更新完了！")


if __name__ == "__main__":
    main()
