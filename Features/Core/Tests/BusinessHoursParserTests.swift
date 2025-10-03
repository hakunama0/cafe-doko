import XCTest
@testable import CafeDokoCore

final class BusinessHoursParserTests: XCTestCase {
    
    // MARK: - 基本的な営業時間判定
    
    func testIsOpen_WithinBusinessHours() {
        // 月曜日の午前10時
        let monday10AM = createDate(weekday: 2, hour: 10, minute: 0)
        
        XCTAssertTrue(
            BusinessHoursParser.isOpen(hoursString: "月-金: 9:00-18:00", at: monday10AM),
            "平日の営業時間内は営業中と判定されるべき"
        )
    }
    
    func testIsOpen_BeforeBusinessHours() {
        // 月曜日の午前8時
        let monday8AM = createDate(weekday: 2, hour: 8, minute: 0)
        
        XCTAssertFalse(
            BusinessHoursParser.isOpen(hoursString: "月-金: 9:00-18:00", at: monday8AM),
            "開店前は閉店中と判定されるべき"
        )
    }
    
    func testIsOpen_AfterBusinessHours() {
        // 月曜日の午後7時
        let monday7PM = createDate(weekday: 2, hour: 19, minute: 0)
        
        XCTAssertFalse(
            BusinessHoursParser.isOpen(hoursString: "月-金: 9:00-18:00", at: monday7PM),
            "閉店後は閉店中と判定されるべき"
        )
    }
    
    func testIsOpen_ExactOpeningTime() {
        // 月曜日の午前9時ちょうど
        let monday9AM = createDate(weekday: 2, hour: 9, minute: 0)
        
        XCTAssertTrue(
            BusinessHoursParser.isOpen(hoursString: "月-金: 9:00-18:00", at: monday9AM),
            "開店時刻ちょうどは営業中と判定されるべき"
        )
    }
    
    func testIsOpen_ExactClosingTime() {
        // 月曜日の午後6時ちょうど
        let monday6PM = createDate(weekday: 2, hour: 18, minute: 0)
        
        XCTAssertFalse(
            BusinessHoursParser.isOpen(hoursString: "月-金: 9:00-18:00", at: monday6PM),
            "閉店時刻ちょうどは閉店中と判定されるべき"
        )
    }
    
    // MARK: - 複数の時間帯
    
    func testIsOpen_MultipleTimeRanges_Weekday() {
        // 月曜日の午前11時
        let monday11AM = createDate(weekday: 2, hour: 11, minute: 0)
        
        XCTAssertTrue(
            BusinessHoursParser.isOpen(hoursString: "月-金: 9:00-18:00, 土日: 10:00-17:00", at: monday11AM),
            "複数時間帯で平日は平日の営業時間を使用すべき"
        )
    }
    
    func testIsOpen_MultipleTimeRanges_Weekend() {
        // 土曜日の午前10時30分
        let saturday10_30AM = createDate(weekday: 7, hour: 10, minute: 30)
        
        XCTAssertTrue(
            BusinessHoursParser.isOpen(hoursString: "月-金: 9:00-18:00, 土日: 10:00-17:00", at: saturday10_30AM),
            "複数時間帯で土日は土日の営業時間を使用すべき"
        )
    }
    
    func testIsOpen_Weekend_BeforeWeekendHours() {
        // 土曜日の午前9時（土日の営業開始前）
        let saturday9AM = createDate(weekday: 7, hour: 9, minute: 0)
        
        XCTAssertFalse(
            BusinessHoursParser.isOpen(hoursString: "月-金: 9:00-18:00, 土日: 10:00-17:00", at: saturday9AM),
            "土日の営業開始前は閉店中と判定されるべき"
        )
    }
    
    // MARK: - 特殊な曜日指定
    
    func testIsOpen_EveryDay() {
        // 水曜日の正午
        let wednesdayNoon = createDate(weekday: 4, hour: 12, minute: 0)
        
        XCTAssertTrue(
            BusinessHoursParser.isOpen(hoursString: "毎日: 8:00-22:00", at: wednesdayNoon),
            "毎日指定は全曜日で営業中と判定されるべき"
        )
    }
    
    func testIsOpen_AllDay() {
        // 日曜日の午後3時
        let sunday3PM = createDate(weekday: 1, hour: 15, minute: 0)
        
        XCTAssertTrue(
            BusinessHoursParser.isOpen(hoursString: "全日: 10:00-20:00", at: sunday3PM),
            "全日指定は全曜日で営業中と判定されるべき"
        )
    }
    
    func testIsOpen_OpenAllYear() {
        // 金曜日の午前11時
        let friday11AM = createDate(weekday: 6, hour: 11, minute: 0)
        
        XCTAssertTrue(
            BusinessHoursParser.isOpen(hoursString: "年中無休: 9:00-21:00", at: friday11AM),
            "年中無休指定は全曜日で営業中と判定されるべき"
        )
    }
    
    // MARK: - エッジケース
    
    func testIsOpen_EmptyString() {
        let monday10AM = createDate(weekday: 2, hour: 10, minute: 0)
        
        XCTAssertFalse(
            BusinessHoursParser.isOpen(hoursString: "", at: monday10AM),
            "空文字列は閉店中と判定されるべき"
        )
    }
    
    func testIsOpen_NilString() {
        let monday10AM = createDate(weekday: 2, hour: 10, minute: 0)
        
        XCTAssertFalse(
            BusinessHoursParser.isOpen(hoursString: nil, at: monday10AM),
            "nilは閉店中と判定されるべき"
        )
    }
    
    func testIsOpen_InvalidFormat() {
        let monday10AM = createDate(weekday: 2, hour: 10, minute: 0)
        
        XCTAssertFalse(
            BusinessHoursParser.isOpen(hoursString: "営業中です", at: monday10AM),
            "無効なフォーマットは閉店中と判定されるべき"
        )
    }
    
    // MARK: - 分単位のテスト
    
    func testIsOpen_WithMinutes() {
        // 月曜日の午前9時30分
        let monday9_30AM = createDate(weekday: 2, hour: 9, minute: 30)
        
        XCTAssertTrue(
            BusinessHoursParser.isOpen(hoursString: "月-金: 9:15-18:45", at: monday9_30AM),
            "分指定の営業時間内は営業中と判定されるべき"
        )
    }
    
    func testIsOpen_JustBeforeClosing() {
        // 月曜日の午後5時59分
        let monday5_59PM = createDate(weekday: 2, hour: 17, minute: 59)
        
        XCTAssertTrue(
            BusinessHoursParser.isOpen(hoursString: "月-金: 9:00-18:00", at: monday5_59PM),
            "閉店1分前は営業中と判定されるべき"
        )
    }
    
    // MARK: - formatHours テスト
    
    func testFormatHours_ValidString() {
        let result = BusinessHoursParser.formatHours("月-金: 9:00-18:00")
        XCTAssertEqual(result, "月-金: 9:00-18:00", "有効な営業時間はそのまま返すべき")
    }
    
    func testFormatHours_NilString() {
        let result = BusinessHoursParser.formatHours(nil)
        XCTAssertNil(result, "nilはnilを返すべき")
    }
    
    func testFormatHours_EmptyString() {
        let result = BusinessHoursParser.formatHours("")
        XCTAssertNil(result, "空文字列はnilを返すべき")
    }
    
    // MARK: - ヘルパーメソッド
    
    /// 指定した曜日と時刻のDateを作成
    /// - Parameters:
    ///   - weekday: 曜日 (1=日, 2=月, ..., 7=土)
    ///   - hour: 時 (0-23)
    ///   - minute: 分 (0-59)
    /// - Returns: 作成されたDate
    private func createDate(weekday: Int, hour: Int, minute: Int) -> Date {
        var components = DateComponents()
        components.calendar = Calendar.current
        components.timeZone = TimeZone.current
        components.year = 2025
        components.month = 10
        
        // 2025年10月の最初の週の指定曜日を計算
        // 10月1日が水曜日なので、そこから計算
        let baseDay = 1 // 2025/10/1
        let baseWeekday = 4 // 水曜日
        let dayOffset = (weekday - baseWeekday + 7) % 7
        components.day = baseDay + dayOffset
        
        components.hour = hour
        components.minute = minute
        components.second = 0
        
        return Calendar.current.date(from: components)!
    }
}

