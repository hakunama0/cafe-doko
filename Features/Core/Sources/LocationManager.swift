import Foundation
import CoreLocation
import os

/// 位置情報を管理するクラス
@Observable
public final class LocationManager: NSObject {
    private let locationManager = CLLocationManager()
    private let logger = Logger(subsystem: "com.cafedoko.app", category: "Location")
    
    public var currentLocation: CLLocation?
    public var authorizationStatus: CLAuthorizationStatus = .notDetermined
    public var isAuthorized: Bool {
        authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways
    }
    
    public override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        authorizationStatus = locationManager.authorizationStatus
    }
    
    /// 位置情報の使用許可をリクエスト
    public func requestPermission() {
        logger.info("📍 位置情報の許可をリクエスト")
        locationManager.requestWhenInUseAuthorization()
    }
    
    /// 現在地を取得
    public func requestLocation() {
        guard isAuthorized else {
            logger.warning("⚠️ 位置情報の許可がありません")
            requestPermission()
            return
        }
        
        logger.info("📍 現在地を取得中...")
        locationManager.requestLocation()
    }
    
    /// デフォルト座標を取得（東京駅）
    public static var defaultCoordinate: (latitude: Double, longitude: Double) {
        (35.6812, 139.7671)
    }
}

extension LocationManager: CLLocationManagerDelegate {
    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        logger.info("📍 位置情報の許可状態: \(String(describing: self.authorizationStatus))")
        
        if isAuthorized {
            requestLocation()
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        currentLocation = location
        logger.info("✅ 現在地取得成功: lat=\(location.coordinate.latitude), lng=\(location.coordinate.longitude)")
    }
    
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        logger.error("❌ 位置情報の取得に失敗: \(error.localizedDescription)")
    }
}

