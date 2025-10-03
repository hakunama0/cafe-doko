import Foundation
import SwiftUI

/// お気に入りカフェを管理するマネージャー
@Observable
public final class FavoritesManager {
    private let defaults = UserDefaults.standard
    private let favoritesKey = "com.cafedoko.favorites"
    
    public private(set) var favoriteIds: Set<UUID> = []
    
    public init() {
        loadFavorites()
    }
    
    // MARK: - Public Methods
    
    /// お気に入りに追加
    public func addFavorite(_ id: UUID) {
        favoriteIds.insert(id)
        saveFavorites()
    }
    
    /// お気に入りから削除
    public func removeFavorite(_ id: UUID) {
        favoriteIds.remove(id)
        saveFavorites()
    }
    
    /// お気に入り状態をトグル
    public func toggleFavorite(_ id: UUID) {
        if favoriteIds.contains(id) {
            removeFavorite(id)
        } else {
            addFavorite(id)
        }
    }
    
    /// IDがお気に入りに含まれているか確認
    public func isFavorite(_ id: UUID) -> Bool {
        favoriteIds.contains(id)
    }
    
    /// お気に入りの数
    public var count: Int {
        favoriteIds.count
    }
    
    /// すべてのお気に入りをクリア
    public func clearAll() {
        favoriteIds.removeAll()
        saveFavorites()
    }
    
    // MARK: - Private Methods
    
    private func loadFavorites() {
        guard let data = defaults.data(forKey: favoritesKey),
              let strings = try? JSONDecoder().decode([String].self, from: data) else {
            return
        }
        
        favoriteIds = Set(strings.compactMap { UUID(uuidString: $0) })
    }
    
    private func saveFavorites() {
        let strings = favoriteIds.map { $0.uuidString }
        if let data = try? JSONEncoder().encode(strings) {
            defaults.set(data, forKey: favoritesKey)
        }
    }
}

