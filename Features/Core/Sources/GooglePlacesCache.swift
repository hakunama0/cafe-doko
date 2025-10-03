import Foundation
import CoreLocation

/// Google Places APIの検索結果をキャッシュする
public actor GooglePlacesCache {
    private var cache: [CacheKey: CacheEntry] = [:]
    private let cacheLifetime: TimeInterval
    
    public init(cacheLifetime: TimeInterval = 300) { // デフォルト5分
        self.cacheLifetime = cacheLifetime
    }
    
    /// キャッシュキー（座標と検索パラメータ）
    public struct CacheKey: Hashable {
        let latitude: Double
        let longitude: Double
        let radius: Double
        
        // 座標の小数点以下3桁まで（約110m精度）で丸める
        init(latitude: Double, longitude: Double, radius: Double) {
            self.latitude = (latitude * 1000).rounded() / 1000
            self.longitude = (longitude * 1000).rounded() / 1000
            self.radius = radius
        }
    }
    
    /// キャッシュエントリ
    struct CacheEntry {
        let places: [GooglePlacesProvider.Place]
        let timestamp: Date
        
        func isValid(lifetime: TimeInterval) -> Bool {
            Date().timeIntervalSince(timestamp) < lifetime
        }
    }
    
    /// キャッシュから取得
    public func get(
        latitude: Double,
        longitude: Double,
        radius: Double
    ) -> [GooglePlacesProvider.Place]? {
        let key = CacheKey(latitude: latitude, longitude: longitude, radius: radius)
        
        guard let entry = cache[key] else {
            return nil
        }
        
        // 有効期限切れの場合は削除
        guard entry.isValid(lifetime: cacheLifetime) else {
            cache.removeValue(forKey: key)
            return nil
        }
        
        return entry.places
    }
    
    /// キャッシュに保存
    public func set(
        latitude: Double,
        longitude: Double,
        radius: Double,
        places: [GooglePlacesProvider.Place]
    ) {
        let key = CacheKey(latitude: latitude, longitude: longitude, radius: radius)
        cache[key] = CacheEntry(places: places, timestamp: Date())
    }
    
    /// キャッシュをクリア
    public func clear() {
        cache.removeAll()
    }
    
    /// 期限切れのエントリを削除
    public func removeExpiredEntries() {
        cache = cache.filter { $0.value.isValid(lifetime: cacheLifetime) }
    }
}

