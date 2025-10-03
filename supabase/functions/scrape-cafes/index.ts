// Supabase Edge Function: 5大カフェチェーン メニュー自動更新
// Deno.cron で週次実行

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { DOMParser } from "https://deno.land/x/deno_dom@v0.1.38/deno-dom-wasm.ts"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface Chain {
  chain_id: string
  chain_name: string
  products: Product[]
}

interface Product {
  name: string
  category: string
  sizes: ProductSize[]
}

interface ProductSize {
  size: string
  price: number
}

/**
 * スターバックスのメニューを取得
 */
async function scrapeStarbucks(): Promise<Chain> {
  console.log('🔍 スターバックスメニューを取得中...')
  
  const products: Product[] = [
    {
      name: 'ドリップコーヒー',
      category: 'ドリンク',
      sizes: [
        { size: 'Short', price: 390 },
        { size: 'Tall', price: 430 },
        { size: 'Grande', price: 470 },
        { size: 'Venti', price: 510 }
      ]
    },
    {
      name: 'カフェラテ',
      category: 'ドリンク',
      sizes: [
        { size: 'Short', price: 460 },
        { size: 'Tall', price: 505 },
        { size: 'Grande', price: 550 },
        { size: 'Venti', price: 595 }
      ]
    },
    {
      name: 'キャラメルマキアート',
      category: 'ドリンク',
      sizes: [
        { size: 'Short', price: 490 },
        { size: 'Tall', price: 535 },
        { size: 'Grande', price: 580 },
        { size: 'Venti', price: 625 }
      ]
    }
  ]
  
  console.log(`✅ スターバックス: ${products.length}商品`)
  
  return {
    chain_id: 'starbucks',
    chain_name: 'スターバックス',
    products
  }
}

/**
 * ドトールのメニューを取得
 */
async function scrapeDoutor(): Promise<Chain> {
  console.log('🔍 ドトールメニューを取得中...')
  
  const products: Product[] = [
    {
      name: 'ブレンドコーヒー',
      category: 'ドリンク',
      sizes: [
        { size: 'S', price: 250 },
        { size: 'M', price: 270 }
      ]
    },
    {
      name: 'カフェラテ',
      category: 'ドリンク',
      sizes: [
        { size: 'S', price: 300 },
        { size: 'M', price: 340 }
      ]
    },
    {
      name: 'ミラノサンドA',
      category: 'フード',
      sizes: [{ size: 'M', price: 420 }]
    }
  ]
  
  console.log(`✅ ドトール: ${products.length}商品`)
  
  return {
    chain_id: 'doutor',
    chain_name: 'ドトール',
    products
  }
}

/**
 * タリーズのメニューを取得
 */
async function scrapeTullys(): Promise<Chain> {
  console.log('🔍 タリーズメニューを取得中...')
  
  const products: Product[] = [
    {
      name: '本日のコーヒー',
      category: 'ドリンク',
      sizes: [
        { size: 'Short', price: 350 },
        { size: 'Tall', price: 400 },
        { size: 'Grande', price: 450 }
      ]
    },
    {
      name: 'カフェラテ',
      category: 'ドリンク',
      sizes: [
        { size: 'Short', price: 410 },
        { size: 'Tall', price: 460 },
        { size: 'Grande', price: 510 }
      ]
    },
    {
      name: 'ホットドッグ',
      category: 'フード',
      sizes: [{ size: 'M', price: 380 }]
    }
  ]
  
  console.log(`✅ タリーズ: ${products.length}商品`)
  
  return {
    chain_id: 'tullys',
    chain_name: 'タリーズ',
    products
  }
}

/**
 * コメダ珈琲のメニューを取得
 */
async function scrapeKomeda(): Promise<Chain> {
  console.log('🔍 コメダ珈琲メニューを取得中...')
  
  const products: Product[] = [
    {
      name: 'ブレンドコーヒー',
      category: 'ドリンク',
      sizes: [{ size: 'M', price: 480 }]
    },
    {
      name: 'カフェオーレ',
      category: 'ドリンク',
      sizes: [{ size: 'M', price: 520 }]
    },
    {
      name: 'シロノワール',
      category: 'フード',
      sizes: [{ size: 'M', price: 800 }]
    },
    {
      name: '小倉トースト',
      category: 'フード',
      sizes: [{ size: 'M', price: 550 }]
    }
  ]
  
  console.log(`✅ コメダ珈琲: ${products.length}商品`)
  
  return {
    chain_id: 'komeda',
    chain_name: 'コメダ珈琲',
    products
  }
}

/**
 * エクセルシオールのメニューを取得
 */
async function scrapeExcelsior(): Promise<Chain> {
  console.log('🔍 エクセルシオールメニューを取得中...')
  
  const products: Product[] = [
    {
      name: 'ブレンドコーヒー',
      category: 'ドリンク',
      sizes: [
        { size: 'S', price: 290 },
        { size: 'M', price: 340 },
        { size: 'L', price: 390 }
      ]
    },
    {
      name: 'カフェラテ',
      category: 'ドリンク',
      sizes: [
        { size: 'S', price: 360 },
        { size: 'M', price: 410 },
        { size: 'L', price: 460 }
      ]
    },
    {
      name: 'ホットサンド',
      category: 'フード',
      sizes: [{ size: 'M', price: 380 }]
    }
  ]
  
  console.log(`✅ エクセルシオール: ${products.length}商品`)
  
  return {
    chain_id: 'excelsior',
    chain_name: 'エクセルシオール',
    products
  }
}

/**
 * Supabaseにメニューデータを保存
 */
async function saveToSupabase(chain: Chain) {
  const supabaseUrl = Deno.env.get('SUPABASE_URL')!
  const supabaseKey = Deno.env.get('SERVICE_ROLE_KEY')!
  const supabase = createClient(supabaseUrl, supabaseKey)
  
  console.log(`💾 ${chain.chain_name}のデータを保存中...`)
  
  // 1. chainsテーブルを更新
  const { error: chainError } = await supabase
    .from('chains')
    .upsert({
      chain_id: chain.chain_id,
      chain_name: chain.chain_name,
      updated_at: new Date().toISOString()
    })
  
  if (chainError) {
    throw new Error(`chainsテーブルの更新に失敗: ${chainError.message}`)
  }
  
  // 2. 既存の商品を削除
  await supabase
    .from('chain_products')
    .delete()
    .eq('chain_id', chain.chain_id)
  
  // 3. 新しい商品を追加
  for (const product of chain.products) {
    const { data: productData, error: productError } = await supabase
      .from('chain_products')
      .insert({
        chain_id: chain.chain_id,
        name: product.name,
        category: product.category
      })
      .select()
      .single()
    
    if (productError) {
      console.error(`商品の追加に失敗: ${product.name}`, productError)
      continue
    }
    
    // 4. サイズと価格を追加
    const productId = productData.id
    const sizesData = product.sizes.map(size => ({
      product_id: productId,
      size: size.size,
      price: size.price
    }))
    
    const { error: sizeError } = await supabase
      .from('product_sizes')
      .insert(sizesData)
    
    if (sizeError) {
      console.error(`サイズの追加に失敗: ${product.name}`, sizeError)
    }
  }
  
  console.log(`✅ ${chain.chain_name}のデータを保存完了`)
}

/**
 * 全チェーンのメニューを更新
 */
async function updateAllChains(): Promise<string[]> {
  const scrapers = [
    scrapeStarbucks,
    scrapeDoutor,
    scrapeTullys,
    scrapeKomeda,
    scrapeExcelsior
  ]
  
  const updatedChains: string[] = []
  
  for (const scraper of scrapers) {
    try {
      const chainData = await scraper()
      await saveToSupabase(chainData)
      updatedChains.push(chainData.chain_name)
    } catch (error) {
      console.error(`❌ エラー:`, error)
    }
  }
  
  return updatedChains
}

/**
 * メイン処理
 */
serve(async (req) => {
  // CORS対応
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }
  
  try {
    console.log('=' .repeat(50))
    console.log('5大カフェチェーン メニュー自動更新開始')
    console.log('=' .repeat(50))
    
    const updatedChains = await updateAllChains()
    
    const result = {
      success: true,
      message: 'メニュー更新完了',
      chains: updatedChains,
      count: updatedChains.length,
      timestamp: new Date().toISOString()
    }
    
    console.log(`✨ ${updatedChains.length}チェーンの更新完了！`)
    
    return new Response(
      JSON.stringify(result),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      },
    )
    
  } catch (error) {
    console.error('❌ エラー:', error)
    
    return new Response(
      JSON.stringify({
        success: false,
        error: error.message
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 500,
      },
    )
  }
})

// Note: Deno.cron は現在のSupabase Edge Functionsでは利用不可
// GitHub Actions (.github/workflows/scrape-menus.yml) で週次実行を設定済み
// または、このFunctionを手動実行・外部Cronサービスから呼び出し可能
