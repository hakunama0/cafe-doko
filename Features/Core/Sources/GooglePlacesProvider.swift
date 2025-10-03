import Foundation
import CoreLocation
import os

public struct GooglePlacesProvider {
    private let apiKey: String
    private let session: URLSession
    private let logger = Logger(subsystem: "com.cafedoko.app", category: "GooglePlaces")
    private let cache: GooglePlacesCache
    
    public enum PlacesError: LocalizedError {
        case invalidResponse
        case networkError(Error)
        case apiError(String)
        case noApiKey
        
        public var errorDescription: String? {
            switch self {
            case .invalidResponse:
                return "Google Places APIからの応答が不正です"
            case .networkError(let error):
                return "ネットワークエラー: \(error.localizedDescription)"
            case .apiError(let message):
                return "APIエラー: \(message)"
            case .noApiKey:
                return "Google Places APIキーが設定されていません"
            }
        }
    }
    
    public struct Place: Codable, Identifiable, Sendable {
        public let id: String
        public let displayName: DisplayName
        public let formattedAddress: String?
        public let location: Location
        public let rating: Double?
        public let userRatingCount: Int?
        public let priceLevel: String?
        public let currentOpeningHours: OpeningHours?
        public let internationalPhoneNumber: String?
        
        public struct DisplayName: Codable, Sendable {
            public let text: String
            public let languageCode: String?
        }
        
        public struct Location: Codable, Sendable {
            public let latitude: Double
            public let longitude: Double
        }
        
        public struct OpeningHours: Codable, Sendable {
            public let openNow: Bool?
            public let weekdayDescriptions: [String]?
        }
    }
    
    private struct SearchNearbyResponse: Codable {
        let places: [Place]?
    }
    
    public init(apiKey: String, session: URLSession = .shared, cache: GooglePlacesCache = GooglePlacesCache()) {
        self.apiKey = apiKey
        self.session = session
        self.cache = cache
    }
    
    /// 近くのカフェを検索
    public func searchNearbyCafes(
        latitude: Double,
        longitude: Double,
        radius: Double = 1000.0,
        maxResults: Int = 20
    ) async throws -> [Place] {
        
        guard !apiKey.isEmpty else {
            throw PlacesError.noApiKey
        }
        
        // キャッシュをチェック
        if let cachedPlaces = await cache.get(latitude: latitude, longitude: longitude, radius: radius) {
            logger.info("💾 キャッシュから\(cachedPlaces.count)件のカフェを取得")
            return cachedPlaces
        }
        
        let url = URL(string: "https://places.googleapis.com/v1/places:searchNearby")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "X-Goog-Api-Key")
        request.setValue(
            "places.id,places.displayName,places.formattedAddress,places.location,places.rating,places.userRatingCount,places.priceLevel,places.currentOpeningHours,places.internationalPhoneNumber",
            forHTTPHeaderField: "X-Goog-FieldMask"
        )
        
        let requestBody: [String: Any] = [
            "includedTypes": ["cafe"],
            "maxResultCount": maxResults,
            "locationRestriction": [
                "circle": [
                    "center": [
                        "latitude": latitude,
                        "longitude": longitude
                    ],
                    "radius": radius
                ]
            ],
            "rankPreference": "DISTANCE"
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        logger.info("🔍 Google Places検索開始: lat=\(latitude), lng=\(longitude), radius=\(radius)m")
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw PlacesError.invalidResponse
            }
            
            logger.info("📡 Google Places応答: status=\(httpResponse.statusCode)")
            
            if httpResponse.statusCode != 200 {
                if let errorMessage = String(data: data, encoding: .utf8) {
                    logger.error("❌ APIエラー: \(errorMessage, privacy: .public)")
                    throw PlacesError.apiError(errorMessage)
                }
                throw PlacesError.invalidResponse
            }
            
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let searchResponse = try decoder.decode(SearchNearbyResponse.self, from: data)
            
            let places = searchResponse.places ?? []
            logger.info("✅ \(places.count)件のカフェを取得しました")
            
            // キャッシュに保存
            await cache.set(latitude: latitude, longitude: longitude, radius: radius, places: places)
            
            return places
            
        } catch let error as PlacesError {
            throw error
        } catch {
            logger.error("❌ ネットワークエラー: \(error.localizedDescription, privacy: .public)")
            throw PlacesError.networkError(error)
        }
    }
}

