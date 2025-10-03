import Foundation
@preconcurrency import CoreLocation
@preconcurrency import CafeDokoCore

/// Google Places APIとSupabaseの価格情報を統合するプロバイダー
public struct HybridCafeProvider: CafeDataProviding {
    private let placesProvider: GooglePlacesCafeProvider
    private let chainMenuManager: ChainMenuManager
    
    public init(
        apiKey: String,
        chainMenuManager: ChainMenuManager,
        userLocation: @escaping () -> (latitude: Double, longitude: Double)? = { nil }
    ) {
        self.placesProvider = GooglePlacesCafeProvider(apiKey: apiKey, userLocation: userLocation)
        self.chainMenuManager = chainMenuManager
    }
    
    public func fetchChains() async throws -> [DokoCafeViewModel.Chain] {
        // Google Placesから近辺のカフェを取得
        var cafes = try await placesProvider.fetchChains()
        
        // 主要チェーンの価格情報でエンリッチ
        cafes = cafes.map { cafe in
            enrichWithChainMenuData(cafe: cafe)
        }
        
        return cafes
    }
    
    /// チェーンメニュー情報でカフェデータをエンリッチ
    private func enrichWithChainMenuData(cafe: DokoCafeViewModel.Chain) -> DokoCafeViewModel.Chain {
        // カフェ名から主要チェーンを判定
        guard let chain = chainMenuManager.detectChain(from: cafe.name) else {
            return cafe
        }
        
        // 代表的な価格を取得
        guard let price = chainMenuManager.getRepresentativePrice(for: chain),
              let defaultProduct = chain.products.first,
              let defaultSize = defaultProduct.sizes.first else {
            return cafe
        }
        
        // 価格情報で上書き
        var enrichedCafe = cafe
        enrichedCafe.price = price
        enrichedCafe.sizeLabel = defaultSize.size
        
        return enrichedCafe
    }
}

