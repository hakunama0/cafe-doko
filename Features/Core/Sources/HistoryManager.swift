import Foundation
import Observation

@Observable
public final class HistoryManager {
    public struct HistoryEntry: Identifiable, Codable, Hashable {
        public let id: UUID
        public let cafeID: UUID
        public let cafeName: String
        public let viewedAt: Date
        
        public init(id: UUID = UUID(), cafeID: UUID, cafeName: String, viewedAt: Date = Date()) {
            self.id = id
            self.cafeID = cafeID
            self.cafeName = cafeName
            self.viewedAt = viewedAt
        }
    }
    
    private let userDefaultsKey = "cafeViewHistory"
    private let maxHistoryCount = 50 // 最大保存件数
    
    public private(set) var entries: [HistoryEntry] {
        didSet {
            saveHistory()
        }
    }
    
    public var count: Int {
        entries.count
    }
    
    public init() {
        self.entries = Self.loadHistory()
    }
    
    /// カフェを閲覧履歴に追加
    public func addEntry(cafeID: UUID, cafeName: String) {
        // 既存のエントリを削除（重複を防ぐ）
        entries.removeAll { $0.cafeID == cafeID }
        
        // 新しいエントリを先頭に追加
        let newEntry = HistoryEntry(cafeID: cafeID, cafeName: cafeName)
        entries.insert(newEntry, at: 0)
        
        // 最大件数を超えた場合は古いものを削除
        if entries.count > maxHistoryCount {
            entries = Array(entries.prefix(maxHistoryCount))
        }
    }
    
    /// 特定のエントリを削除
    public func removeEntry(_ entryID: UUID) {
        entries.removeAll { $0.id == entryID }
    }
    
    /// すべての履歴をクリア
    public func clearAll() {
        entries.removeAll()
    }
    
    private func saveHistory() {
        if let encoded = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }
    
    private static func loadHistory() -> [HistoryEntry] {
        if let savedData = UserDefaults.standard.data(forKey: "cafeViewHistory"),
           let decoded = try? JSONDecoder().decode([HistoryEntry].self, from: savedData) {
            return decoded
        }
        return []
    }
}

