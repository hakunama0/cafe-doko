#!/usr/bin/env python3
"""
チェーン店メニューデータをSupabaseにインポートするスクリプト
"""
import json
import os
from supabase import create_client, Client

# Supabase接続情報
SUPABASE_URL = "https://dlwjajmdqopypgzkiwut.supabase.co"
SUPABASE_KEY = os.getenv("CAFE_DOKO_API_KEY")

if not SUPABASE_KEY:
    print("❌ 環境変数 CAFE_DOKO_API_KEY が設定されていません")
    print("実行方法: CAFE_DOKO_API_KEY=your_key python3 Scripts/import_chains_to_supabase.py")
    exit(1)

# Supabaseクライアント初期化
supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

def import_chains():
    """ChainsMenu.jsonからデータを読み込んでSupabaseに投入"""
    
    # JSONファイルを読み込み
    with open("Resources/ChainsMenu.json", "r", encoding="utf-8") as f:
        data = json.load(f)
    
    chains = data["chains"]
    print(f"📚 {len(chains)}個のチェーン店を処理します\n")
    
    for chain in chains:
        chain_id = chain["id"]
        chain_name = chain["name"]
        keywords = chain["keywords"]
        
        print(f"🏪 {chain_name} を処理中...")
        
        # 1. チェーン店マスターに挿入
        try:
            chain_result = supabase.table("chains").upsert({
                "id": chain_id,
                "name": chain_name,
                "keywords": keywords
            }).execute()
            print(f"  ✅ チェーン店マスター登録完了")
        except Exception as e:
            print(f"  ❌ チェーン店マスター登録エラー: {e}")
            continue
        
        # 2. 商品とサイズを挿入
        product_count = 0
        size_count = 0
        
        for product in chain["products"]:
            try:
                # 商品を挿入
                product_result = supabase.table("chain_products").insert({
                    "chain_id": chain_id,
                    "name": product["name"],
                    "category": product["category"]
                }).execute()
                
                product_id = product_result.data[0]["id"]
                product_count += 1
                
                # サイズと価格を挿入
                for size in product["sizes"]:
                    supabase.table("product_sizes").insert({
                        "product_id": product_id,
                        "size": size["size"],
                        "price": size["price"]
                    }).execute()
                    size_count += 1
                
            except Exception as e:
                print(f"  ⚠️  商品 {product['name']} 登録エラー: {e}")
        
        print(f"  ✅ 商品 {product_count}件、サイズ {size_count}件 登録完了\n")
    
    print("🎉 すべてのデータのインポートが完了しました！")

def verify_data():
    """データが正しく登録されているか確認"""
    print("\n📊 データ確認中...")
    
    chains_count = supabase.table("chains").select("id", count="exact").execute()
    products_count = supabase.table("chain_products").select("id", count="exact").execute()
    sizes_count = supabase.table("product_sizes").select("id", count="exact").execute()
    
    print(f"  チェーン店: {chains_count.count}件")
    print(f"  商品: {products_count.count}件")
    print(f"  サイズ: {sizes_count.count}件")

if __name__ == "__main__":
    print("=" * 60)
    print("  チェーン店メニューデータ Supabase インポートツール")
    print("=" * 60)
    print()
    
    import_chains()
    verify_data()
    
    print("\n✨ 完了！")

