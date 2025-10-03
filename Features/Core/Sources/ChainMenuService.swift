import Foundation
import os

/// Supabaseからチェーン店のメニュー・価格情報を取得するサービス
public struct ChainMenuService {
    private let supabaseURL: String
    private let apiKey: String
    private let session: URLSession
    private let logger = Logger(subsystem: "com.cafedoko.app", category: "ChainMenu")
    
    public enum ServiceError: LocalizedError {
        case invalidResponse
        case networkError(Error)
        case apiError(String)
        case noApiKey
        
        public var errorDescription: String? {
            switch self {
            case .invalidResponse:
                return "メニュー情報の応答が不正です"
            case .networkError(let error):
                return "ネットワークエラー: \(error.localizedDescription)"
            case .apiError(let message):
                return "APIエラー: \(message)"
            case .noApiKey:
                return "APIキーが設定されていません"
            }
        }
    }
    
    public struct ChainMenu: Codable, Sendable {
        public let id: String
        public let name: String
        public let products: [Product]?
        
        public struct Product: Codable, Sendable {
            public let id: Int
            public let name: String
            public let category: String
            public let sizes: [ProductSize]?
            
            enum CodingKeys: String, CodingKey {
                case id, name, category, sizes = "product_sizes"
            }
        }
        
        public struct ProductSize: Codable, Sendable {
            public let size: String
            public let price: Int
        }
        
        enum CodingKeys: String, CodingKey {
            case id = "chain_id"
            case name = "chain_name"
            case products = "chain_products"
        }
    }
    
    public init(supabaseURL: String, apiKey: String, session: URLSession = .shared) {
        self.supabaseURL = supabaseURL
        self.apiKey = apiKey
        self.session = session
    }
    
    /// チェーンIDからメニュー情報を取得
    public func fetchChainMenu(chainId: String) async throws -> ChainMenu {
        guard !apiKey.isEmpty else {
            throw ServiceError.noApiKey
        }
        
        // Supabaseのクエリ: chainsテーブルからchain_productsを結合して取得
        let query = "\(supabaseURL)/rest/v1/chains?chain_id=eq.\(chainId)&select=chain_id,chain_name,chain_products(id,name,category,product_sizes(size,price))"
        
        guard let url = URL(string: query) else {
            throw ServiceError.invalidResponse
        }
        
        var request = URLRequest(url: url)
        request.setValue(apiKey, forHTTPHeaderField: "apikey")
        request.setValue(apiKey, forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        logger.info("🍽️ メニュー情報取得開始: chainId=\(chainId)")
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw ServiceError.invalidResponse
            }
            
            logger.info("📡 Supabase応答: status=\(httpResponse.statusCode)")
            
            if httpResponse.statusCode != 200 {
                if let errorMessage = String(data: data, encoding: .utf8) {
                    logger.error("❌ APIエラー: \(errorMessage, privacy: .public)")
                    throw ServiceError.apiError(errorMessage)
                }
                throw ServiceError.invalidResponse
            }
            
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let menus = try decoder.decode([ChainMenu].self, from: data)
            
            guard let menu = menus.first else {
                throw ServiceError.invalidResponse
            }
            
            logger.info("✅ メニュー情報取得成功: \(menu.products?.count ?? 0)商品")
            
            return menu
            
        } catch let error as ServiceError {
            throw error
        } catch {
            logger.error("❌ ネットワークエラー: \(error.localizedDescription, privacy: .public)")
            throw ServiceError.networkError(error)
        }
    }
    
    /// カフェ名からチェーンを推定してメニューを取得
    public func fetchMenuByCafeName(name: String) async throws -> ChainMenu? {
        let normalizedName = name.lowercased()
        
        let chainMapping: [String: String] = [
            "スターバックス": "starbucks",
            "starbucks": "starbucks",
            "ドトール": "doutor",
            "doutor": "doutor",
            "タリーズ": "tullys",
            "tully": "tullys",
            "コメダ": "komeda",
            "komeda": "komeda",
            "エクセルシオール": "excelsior",
            "excelsior": "excelsior"
        ]
        
        for (pattern, chainId) in chainMapping {
            if normalizedName.contains(pattern.lowercased()) {
                logger.info("🔍 チェーン検出: \(name) → \(chainId)")
                return try await fetchChainMenu(chainId: chainId)
            }
        }
        
        logger.info("ℹ️ 該当するチェーンなし: \(name)")
        return nil
    }
}

