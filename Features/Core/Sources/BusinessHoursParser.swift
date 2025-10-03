import Foundation

/// 営業時間をパースして営業状況を判定するユーティリティ
public struct BusinessHoursParser {
    
    /// 営業時間の文字列から現在の営業状況を判定
    /// - Parameter hoursString: 営業時間の文字列（例: "月-金: 9:00-18:00, 土日: 10:00-17:00"）
    /// - Returns: 営業中の場合true、閉店中の場合false
    public static func isOpen(hoursString: String?, at date: Date = Date()) -> Bool {
        guard let hoursString = hoursString, !hoursString.isEmpty else {
            return false
        }
        
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
        let currentMinutes = hour * 60 + minute
        
        // 営業時間をパース
        let segments = hoursString.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        
        for segment in segments {
            // "月-金: 9:00-18:00" または "土日: 10:00-17:00" の形式を想定
            // コロンでsplitすると時刻部分が分割されるので、最初のコロンで分ける
            guard let colonIndex = segment.firstIndex(of: ":") else { continue }
            
            let dayPart = String(segment[..<colonIndex]).trimmingCharacters(in: .whitespaces)
            let timePart = String(segment[segment.index(after: colonIndex)...]).trimmingCharacters(in: .whitespaces)
            
            // 曜日の判定
            if matchesWeekday(weekday, dayPart: dayPart) {
                // 時間範囲をパース
                if let (openMinutes, closeMinutes) = parseTimeRange(timePart) {
                    if currentMinutes >= openMinutes && currentMinutes < closeMinutes {
                        return true
                    }
                }
            }
        }
        
        return false
    }
    
    /// 曜日文字列が現在の曜日にマッチするか判定
    /// - Parameters:
    ///   - weekday: Calendar.component(.weekday) の値 (1=日, 2=月, ..., 7=土)
    ///   - dayPart: 曜日の文字列 ("月-金", "土日", "毎日" など)
    /// - Returns: マッチする場合true
    private static func matchesWeekday(_ weekday: Int, dayPart: String) -> Bool {
        let dayPart = dayPart.trimmingCharacters(in: .whitespaces)
        
        // "毎日" または "全日"
        if dayPart.contains("毎日") || dayPart.contains("全日") || dayPart.contains("年中無休") {
            return true
        }
        
        // "月-金" のような範囲
        if dayPart.contains("-") {
            let rangeParts = dayPart.split(separator: "-")
            if rangeParts.count == 2 {
                let startDay = weekdayNumber(from: String(rangeParts[0]))
                let endDay = weekdayNumber(from: String(rangeParts[1]))
                if let start = startDay, let end = endDay {
                    // 週をまたぐ範囲の場合（例: 金-月）
                    if start <= end {
                        return weekday >= start && weekday <= end
                    } else {
                        return weekday >= start || weekday <= end
                    }
                }
            }
        }
        
        // "土日" のような複数指定
        let weekdayChars = ["日", "月", "火", "水", "木", "金", "土"]
        if weekday >= 1 && weekday <= 7 {
            let currentDayChar = weekdayChars[weekday - 1]
            if dayPart.contains(currentDayChar) {
                return true
            }
        }
        
        return false
    }
    
    /// 曜日文字列から weekday 番号に変換
    /// - Parameter dayString: 曜日の文字列 ("月", "火", etc.)
    /// - Returns: weekday 番号 (1=日, 2=月, ..., 7=土)
    private static func weekdayNumber(from dayString: String) -> Int? {
        let mapping: [String: Int] = [
            "日": 1, "月": 2, "火": 3, "水": 4,
            "木": 5, "金": 6, "土": 7
        ]
        return mapping[dayString]
    }
    
    /// 時間範囲の文字列をパース
    /// - Parameter timeRange: 時間範囲の文字列 ("9:00-18:00")
    /// - Returns: (開店時刻の分, 閉店時刻の分) のタプル
    private static func parseTimeRange(_ timeRange: String) -> (Int, Int)? {
        let parts = timeRange.split(separator: "-").map { $0.trimmingCharacters(in: .whitespaces) }
        guard parts.count == 2 else { return nil }
        
        guard let openMinutes = parseTime(String(parts[0])),
              let closeMinutes = parseTime(String(parts[1])) else {
            return nil
        }
        
        return (openMinutes, closeMinutes)
    }
    
    /// 時刻文字列を分単位に変換
    /// - Parameter timeString: 時刻の文字列 ("9:00", "18:30")
    /// - Returns: 0時からの経過分数
    private static func parseTime(_ timeString: String) -> Int? {
        let components = timeString.split(separator: ":").map { String($0) }
        guard components.count == 2,
              let hour = Int(components[0]),
              let minute = Int(components[1]) else {
            return nil
        }
        return hour * 60 + minute
    }
    
    /// 営業時間の文字列をフォーマットして読みやすくする
    /// - Parameter hoursString: 営業時間の文字列
    /// - Returns: フォーマット済みの文字列
    public static func formatHours(_ hoursString: String?) -> String? {
        guard let hoursString = hoursString, !hoursString.isEmpty else {
            return nil
        }
        // 現在は入力をそのまま返すが、将来的により高度なフォーマットを実装可能
        return hoursString
    }
}

