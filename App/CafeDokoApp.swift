import SwiftUI
import DokoCafeFeature
import CafeDokoCore
import UserNotifications

@main
struct CafeDokoApp: App {
    @State private var model: RootAppModel
    @State private var cafeModel: DokoCafeViewModel
    @State private var favoritesManager = FavoritesManager()
    @State private var historyManager = HistoryManager()
    @State private var settingsManager = SettingsManager()
    @State private var chainMenuManager = ChainMenuManager()
    @State private var locationManager = LocationManager()
    @State private var notificationManager = NotificationManager()

    init() {
        _model = State(initialValue: RootAppModel(milestones: .sample()))
        
        // LocationManagerを先に初期化
        let locationMgr = LocationManager()
        _locationManager = State(initialValue: locationMgr)
        _notificationManager = State(initialValue: NotificationManager())

        let config = (try? CafeConfigLoader().loadConfig()) ?? CafeConfig(provider: .mock)
        let viewModel: DokoCafeViewModel

        switch config.provider {
        case .mock:
            // Mock mode is deprecated for production
            // Falls back to empty data provider
            let provider = EmptyCafeDataProvider()
            viewModel = DokoCafeViewModel(dataProvider: provider, imageProvider: SymbolCafeImageProvider())
            
        case .remote:
            if let url = config.remoteURL {
                let provider = RemoteCafeDataProvider(
                    requestFactory: Self.requestFactory(
                        url: url,
                        headers: config.headers,
                        baseHeaders: Self.defaultHeaders
                    )
                )
                viewModel = DokoCafeViewModel(dataProvider: provider, imageProvider: SymbolCafeImageProvider())
            } else {
                // Invalid configuration - use empty provider
                let provider = EmptyCafeDataProvider()
                viewModel = DokoCafeViewModel(dataProvider: provider, imageProvider: SymbolCafeImageProvider())
            }
            
        case .google_places:
            if let apiKey = config.googlePlacesApiKey, !apiKey.isEmpty {
                // LocationManagerから現在地を取得するクロージャを渡す
                let provider = GooglePlacesCafeProvider(apiKey: apiKey) { [locationMgr] in
                    guard let location = locationMgr.currentLocation else { return nil }
                    return (latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
                }
                viewModel = DokoCafeViewModel(dataProvider: provider, imageProvider: SymbolCafeImageProvider())
            } else {
                // Missing API key - use empty provider
                let provider = EmptyCafeDataProvider()
                viewModel = DokoCafeViewModel(dataProvider: provider, imageProvider: SymbolCafeImageProvider())
            }
        }

        _cafeModel = State(initialValue: viewModel)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(model)
                .environment(cafeModel)
                .environment(favoritesManager)
                .environment(historyManager)
                .environment(settingsManager)
                .environment(chainMenuManager)
                .environment(locationManager)
                .environment(notificationManager)
                .task {
                    // 通知デリゲートを設定
                    UNUserNotificationCenter.current().delegate = notificationManager
                    
                    // 位置情報の許可をリクエスト
                    locationManager.requestPermission()
                    
                    // 通知の許可をリクエスト（初回のみ表示される）
                    await notificationManager.requestPermission()
                    
                    await cafeModel.reload()
                }
        }
    }

    private static var defaultHeaders: [String: String] {
        [
            "Accept": "application/json",
            "Accept-Language": Locale.preferredLanguages.joined(separator: ","),
            "User-Agent": Self.userAgent
        ]
    }

    private static var userAgent: String {
        let bundleVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0"
        return "CafeDokoApp/\(bundleVersion) (iOS)"
    }

    private static func requestFactory(
        url: URL,
        headers: [String: String],
        baseHeaders: [String: String]
    ) -> CafeDataProviderConfiguration.URLRequestFactory {
        {
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            baseHeaders.forEach { request.setValue($1, forHTTPHeaderField: $0) }
            headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }
            return request
        }
    }
}
