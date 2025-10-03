import Foundation
import Observation

@Observable
public final class ChainMenuManager {
    public struct Chain: Codable, Identifiable, Sendable {
        public let id: String
        public let name: String
        public let keywords: [String]
        public let products: [Product]
    }
    
    public struct Product: Codable, Identifiable, Sendable {
        public var id: String { name }
        public let name: String
        public let category: String
        public let sizes: [Size]
    }
    
    public struct Size: Codable, Sendable {
        public let size: String
        public let price: Int
    }
    
    private struct MenuData: Codable {
        let chains: [Chain]
    }
    
    public private(set) var chains: [Chain] = []
    
    public init() {
        loadMenu()
    }
    
    private func loadMenu() {
        guard let url = Bundle.main.url(forResource: "ChainsMenu", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let menuData = try? JSONDecoder().decode(MenuData.self, from: data) else {
            print("❌ ChainsMenu.json の読み込みに失敗しました")
            return
        }
        chains = menuData.chains
        print("✅ \(chains.count)個のチェーン店メニューを読み込みました")
    }
    
    /// カフェ名からチェーンを判定
    public func detectChain(from cafeName: String) -> Chain? {
        for chain in chains {
            for keyword in chain.keywords {
                if cafeName.contains(keyword) {
                    return chain
                }
            }
        }
        return nil
    }
    
    /// チェーンの代表的な商品価格を取得（最小サイズ）
    public func getRepresentativePrice(for chain: Chain) -> Int? {
        // 最も一般的な商品の最小価格を返す
        let commonProducts = ["ドリップコーヒー", "ブレンドコーヒー", "本日のコーヒー"]
        for productName in commonProducts {
            if let product = chain.products.first(where: { $0.name == productName }),
               let firstSize = product.sizes.first {
                return firstSize.price
            }
        }
        // 見つからない場合は最初の商品の最小価格
        return chain.products.first?.sizes.first?.price
    }
    
    /// チェーンの平均価格を計算
    public func getAveragePrice(for chain: Chain) -> Int {
        let allPrices = chain.products.flatMap { $0.sizes.map { $0.price } }
        guard !allPrices.isEmpty else { return 0 }
        return allPrices.reduce(0, +) / allPrices.count
    }
}

