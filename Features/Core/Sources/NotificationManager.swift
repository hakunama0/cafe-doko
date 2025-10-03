import Foundation
import UserNotifications
import os

/// プッシュ通知を管理するクラス
@Observable
public final class NotificationManager: NSObject {
    private let logger = Logger(subsystem: "com.cafedoko.app", category: "Notification")
    
    public var authorizationStatus: UNAuthorizationStatus = .notDetermined
    public var isAuthorized: Bool {
        authorizationStatus == .authorized || authorizationStatus == .provisional
    }
    
    public override init() {
        super.init()
        checkAuthorizationStatus()
    }
    
    /// 通知の許可をリクエスト
    public func requestPermission() async {
        logger.info("🔔 通知の許可をリクエスト")
        
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .sound, .badge]
            )
            
            if granted {
                logger.info("✅ 通知の許可が得られました")
                await checkAuthorizationStatus()
            } else {
                logger.warning("⚠️ 通知の許可が拒否されました")
            }
        } catch {
            logger.error("❌ 通知の許可リクエストに失敗: \(error.localizedDescription)")
        }
    }
    
    /// 現在の許可状態を確認
    @MainActor
    public func checkAuthorizationStatus() {
        Task {
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            authorizationStatus = settings.authorizationStatus
            logger.info("📋 通知の許可状態: \(String(describing: authorizationStatus))")
        }
    }
    
    /// ローカル通知をスケジュール
    public func scheduleNotification(
        title: String,
        body: String,
        identifier: String,
        timeInterval: TimeInterval
    ) async {
        guard isAuthorized else {
            logger.warning("⚠️ 通知の許可がありません")
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: timeInterval,
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )
        
        do {
            try await UNUserNotificationCenter.current().add(request)
            logger.info("✅ 通知をスケジュール: \(title)")
        } catch {
            logger.error("❌ 通知のスケジュールに失敗: \(error.localizedDescription)")
        }
    }
    
    /// 特定の通知をキャンセル
    public func cancelNotification(identifier: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [identifier]
        )
        logger.info("🗑️ 通知をキャンセル: \(identifier)")
    }
    
    /// すべての通知をキャンセル
    public func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        logger.info("🗑️ すべての通知をキャンセル")
    }
    
    /// お気に入りカフェの営業開始通知をスケジュール
    public func scheduleOpeningNotification(cafeName: String, openingTime: Date) async {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: openingTime)
        
        let content = UNMutableNotificationContent()
        content.title = "☕️ \(cafeName)が営業開始"
        content.body = "お気に入りのカフェが営業を開始しました"
        content.sound = .default
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: components,
            repeats: true
        )
        
        let identifier = "opening-\(cafeName.replacingOccurrences(of: " ", with: "-"))"
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )
        
        do {
            try await UNUserNotificationCenter.current().add(request)
            logger.info("✅ 営業開始通知をスケジュール: \(cafeName)")
        } catch {
            logger.error("❌ 営業開始通知のスケジュールに失敗: \(error.localizedDescription)")
        }
    }
}

extension NotificationManager: UNUserNotificationCenterDelegate {
    /// アプリがフォアグラウンドにある時の通知表示
    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        logger.info("🔔 通知を受信: \(notification.request.content.title)")
        return [.banner, .sound, .badge]
    }
    
    /// 通知をタップした時の処理
    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        logger.info("👆 通知をタップ: \(response.notification.request.identifier)")
        // TODO: 通知に応じた画面遷移などの処理
    }
}

