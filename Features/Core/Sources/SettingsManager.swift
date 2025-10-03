import Foundation
import Observation

@Observable
public final class SettingsManager {
    private let userDefaults = UserDefaults.standard
    
    // Keys
    private enum Keys {
        static let defaultViewMode = "defaultViewMode"
        static let defaultSortOption = "defaultSortOption"
        static let newCafeNotification = "newCafeNotification"
        static let favoriteOpeningNotification = "favoriteOpeningNotification"
    }
    
    // Default View Mode
    public enum ViewMode: String, CaseIterable, Identifiable {
        case list = "リスト"
        case map = "地図"
        
        public var id: String { rawValue }
    }
    
    // Sort Option
    public enum SortOption: String, CaseIterable, Identifiable {
        case recommended = "おすすめ順"
        case nearby = "近い順"
        case priceLow = "価格が安い順"
        
        public var id: String { rawValue }
    }
    
    public var defaultViewMode: ViewMode {
        get {
            if let rawValue = userDefaults.string(forKey: Keys.defaultViewMode),
               let mode = ViewMode(rawValue: rawValue) {
                return mode
            }
            return .list
        }
        set {
            userDefaults.set(newValue.rawValue, forKey: Keys.defaultViewMode)
        }
    }
    
    public var defaultSortOption: SortOption {
        get {
            if let rawValue = userDefaults.string(forKey: Keys.defaultSortOption),
               let option = SortOption(rawValue: rawValue) {
                return option
            }
            return .recommended
        }
        set {
            userDefaults.set(newValue.rawValue, forKey: Keys.defaultSortOption)
        }
    }
    
    public var newCafeNotificationEnabled: Bool {
        get {
            userDefaults.bool(forKey: Keys.newCafeNotification)
        }
        set {
            userDefaults.set(newValue, forKey: Keys.newCafeNotification)
        }
    }
    
    public var favoriteOpeningNotificationEnabled: Bool {
        get {
            userDefaults.bool(forKey: Keys.favoriteOpeningNotification)
        }
        set {
            userDefaults.set(newValue, forKey: Keys.favoriteOpeningNotification)
        }
    }
    
    public init() {}
    
    /// Clear all cache data (UserDefaults, URLCache, etc.)
    public func clearCache() {
        // URLCacheをクリア（画像などのネットワークキャッシュ）
        URLCache.shared.removeAllCachedResponses()
        
        // 一時ファイルディレクトリをクリア
        if let tmpDirectory = try? FileManager.default.contentsOfDirectory(
            at: FileManager.default.temporaryDirectory,
            includingPropertiesForKeys: nil
        ) {
            for fileURL in tmpDirectory {
                try? FileManager.default.removeItem(at: fileURL)
            }
        }
        
        // Google Places APIのキャッシュは自動的に5分で期限切れになります
        // 必要に応じてアプリを再起動するか、時間経過を待ってください
        
        print("✅ キャッシュをクリアしました")
    }
    
    /// Reset all settings to default values
    public func resetSettings() {
        defaultViewMode = .list
        defaultSortOption = .recommended
        newCafeNotificationEnabled = false
        favoriteOpeningNotificationEnabled = false
        print("✅ 設定をリセットしました")
    }
}

