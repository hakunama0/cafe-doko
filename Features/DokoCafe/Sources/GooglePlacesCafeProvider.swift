import Foundation
@preconcurrency import CoreLocation
@preconcurrency import CafeDokoCore

/// Google Places APIを使用してカフェデータを取得するプロバイダー
public struct GooglePlacesCafeProvider: CafeDataProviding {
    private let placesProvider: GooglePlacesProvider
    private let locationManager: CLLocationManager
    
    public init(apiKey: String) {
        self.placesProvider = GooglePlacesProvider(apiKey: apiKey)
        self.locationManager = CLLocationManager()
    }
    
    public func fetchChains() async throws -> [DokoCafeViewModel.Chain] {
        // 現在地を取得（仮の東京駅座標）
        let latitude = 35.6812
        let longitude = 139.7671
        
        // Google Places APIで近くのカフェを検索
        let places = try await placesProvider.searchNearbyCafes(
            latitude: latitude,
            longitude: longitude,
            radius: 1000.0,
            maxResults: 20
        )
        
        // Google PlacesのデータをDokoCafeViewModel.Chainに変換
        return places.map { place in
            convertToChain(place: place, userLocation: (latitude, longitude))
        }
    }
    
    private func convertToChain(
        place: GooglePlacesProvider.Place,
        userLocation: (lat: Double, lng: Double)
    ) -> DokoCafeViewModel.Chain {
        // 距離を計算
        let distance = calculateDistance(
            from: userLocation,
            to: (place.location.latitude, place.location.longitude)
        )
        
        // 価格レベルを円に変換（Google Placesの価格レベルは $ ~ $$$$）
        let estimatedPrice = estimatePrice(from: place.priceLevel)
        
        // 営業時間の文字列を生成
        let openingHours = place.currentOpeningHours?.weekdayDescriptions?.first
        
        // タグを生成
        var tags: [String] = []
        if let rating = place.rating, rating >= 4.0 {
            tags.append("高評価")
        }
        if let openNow = place.currentOpeningHours?.openNow, openNow {
            tags.append("営業中")
        }
        
        // Google Places IDをUUIDに変換（ハッシュを使用）
        let uuidString = place.id.data(using: .utf8)?.base64EncodedString()
            .replacingOccurrences(of: "/", with: "")
            .replacingOccurrences(of: "+", with: "")
            .prefix(32) ?? ""
        let formattedUUID = String(format: "%@-%@-%@-%@-%@",
                                   String(uuidString.prefix(8)),
                                   String(uuidString.dropFirst(8).prefix(4)),
                                   String(uuidString.dropFirst(12).prefix(4)),
                                   String(uuidString.dropFirst(16).prefix(4)),
                                   String(uuidString.dropFirst(20).prefix(12)))
        let uuid = UUID(uuidString: formattedUUID) ?? UUID()
        
        return DokoCafeViewModel.Chain(
            id: uuid,
            name: place.displayName.text,
            price: estimatedPrice,
            sizeLabel: "M",  // デフォルト
            distance: distance,
            tags: tags,
            imageURL: nil,  // Google Places Photosは別途実装が必要
            updatedAt: Date(),
            address: place.formattedAddress,
            openingHours: openingHours,
            phoneNumber: place.internationalPhoneNumber,
            latitude: place.location.latitude,
            longitude: place.location.longitude
        )
    }
    
    /// 2点間の距離を計算（メートル）
    private func calculateDistance(
        from: (lat: Double, lng: Double),
        to: (lat: Double, lng: Double)
    ) -> Int {
        let location1 = CLLocation(latitude: from.lat, longitude: from.lng)
        let location2 = CLLocation(latitude: to.lat, longitude: to.lng)
        let distanceInMeters = location1.distance(from: location2)
        return Int(distanceInMeters)
    }
    
    /// Google Placesの価格レベルから日本円を推定
    private func estimatePrice(from priceLevel: String?) -> Int {
        guard let priceLevel = priceLevel else {
            return 400  // デフォルト価格
        }
        
        switch priceLevel {
        case "PRICE_LEVEL_INEXPENSIVE":
            return 300
        case "PRICE_LEVEL_MODERATE":
            return 450
        case "PRICE_LEVEL_EXPENSIVE":
            return 600
        case "PRICE_LEVEL_VERY_EXPENSIVE":
            return 800
        default:
            return 400
        }
    }
}

