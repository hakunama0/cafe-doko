import SwiftUI
import CafeDokoCore

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(NotificationManager.self) private var notificationManager
    @State private var showingClearCacheAlert = false
    @State private var showingResetFavoritesAlert = false
    @State private var showingResetSettingsAlert = false
    
    @Bindable var settingsManager: SettingsManager
    @Bindable var favoritesManager: FavoritesManager
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    SettingsSection(title: "表示設定") {
                        VStack(spacing: 0) {
                            Picker("デフォルト表示モード", selection: $settingsManager.defaultViewMode) {
                                ForEach(SettingsManager.ViewMode.allCases) { mode in
                                    Text(mode.rawValue).tag(mode)
                                }
                            }
                            .pickerStyle(.menu)
                            .padding()
                            
                            Divider()
                                .background(.white.opacity(0.1))
                            
                            Picker("デフォルトソート", selection: $settingsManager.defaultSortOption) {
                                ForEach(SettingsManager.SortOption.allCases) { option in
                                    Text(option.rawValue).tag(option)
                                }
                            }
                            .pickerStyle(.menu)
                            .padding()
                        }
                    }
                    
                    SettingsSection(title: "通知") {
                        VStack(spacing: 0) {
                            Toggle("新しいカフェの通知", isOn: $settingsManager.newCafeNotificationEnabled)
                                .padding()
                                .onChange(of: settingsManager.newCafeNotificationEnabled) { oldValue, newValue in
                                    if newValue {
                                        Task {
                                            await notificationManager.requestPermission()
                                        }
                                    }
                                }
                            
                            Divider()
                                .background(.white.opacity(0.1))
                            
                            Toggle("お気に入りの営業開始通知", isOn: $settingsManager.favoriteOpeningNotificationEnabled)
                                .padding()
                                .onChange(of: settingsManager.favoriteOpeningNotificationEnabled) { oldValue, newValue in
                                    if newValue {
                                        Task {
                                            await notificationManager.requestPermission()
                                        }
                                    } else {
                                        notificationManager.cancelAllNotifications()
                                    }
                                }
                        }
                    }
                    
                    SettingsSection(title: "データ") {
                        VStack(spacing: 0) {
                            Button {
                                showingClearCacheAlert = true
                            } label: {
                                HStack {
                                    Text("キャッシュをクリア")
                                        .foregroundStyle(.primary)
                                    Spacer()
                                }
                                .contentShape(Rectangle())
                            }
                            .padding()
                            
                            Divider()
                                .background(.white.opacity(0.1))
                            
                            Button(role: .destructive) {
                                showingResetFavoritesAlert = true
                            } label: {
                                HStack {
                                    Text("お気に入りをリセット")
                                    Spacer()
                                }
                                .contentShape(Rectangle())
                            }
                            .padding()
                            
                            Divider()
                                .background(.white.opacity(0.1))
                            
                            Button(role: .destructive) {
                                showingResetSettingsAlert = true
                            } label: {
                                HStack {
                                    Text("設定をリセット")
                                    Spacer()
                                }
                                .contentShape(Rectangle())
                            }
                            .padding()
                        }
                    }
                    
                    SettingsSection(title: "アプリ情報") {
                        VStack(spacing: 0) {
                            HStack {
                                Text("バージョン")
                                    .foregroundStyle(.primary)
                                Spacer()
                                Text(appVersion)
                                    .foregroundStyle(.secondary)
                            }
                            .padding()
                            
                            Divider()
                                .background(.white.opacity(0.1))
                            
                            Link(destination: URL(string: "https://example.com")!) {
                                HStack {
                                    Text("プライバシーポリシー")
                                        .foregroundStyle(.primary)
                                    Spacer()
                                    Image(systemName: "arrow.up.right.square")
                                        .foregroundStyle(.blue)
                                }
                            }
                            .padding()
                            
                            Divider()
                                .background(.white.opacity(0.1))
                            
                            Link(destination: URL(string: "https://example.com")!) {
                                HStack {
                                    Text("利用規約")
                                        .foregroundStyle(.primary)
                                    Spacer()
                                    Image(systemName: "arrow.up.right.square")
                                        .foregroundStyle(.blue)
                                }
                            }
                            .padding()
                        }
                    }
                }
                .padding(24)
            }
            .background(BackgroundGradient())
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完了") {
                        dismiss()
                    }
                }
            }
            .alert("キャッシュをクリア", isPresented: $showingClearCacheAlert) {
                Button("キャンセル", role: .cancel) { }
                Button("クリア", role: .destructive) {
                    settingsManager.clearCache()
                }
            } message: {
                Text("アプリのキャッシュをクリアしますか？")
            }
            .alert("お気に入りをリセット", isPresented: $showingResetFavoritesAlert) {
                Button("キャンセル", role: .cancel) { }
                Button("リセット", role: .destructive) {
                    favoritesManager.clearAll()
                }
            } message: {
                Text("すべてのお気に入りを削除しますか？この操作は取り消せません。")
            }
            .alert("設定をリセット", isPresented: $showingResetSettingsAlert) {
                Button("キャンセル", role: .cancel) { }
                Button("リセット", role: .destructive) {
                    settingsManager.resetSettings()
                }
            } message: {
                Text("すべての設定がデフォルト値に戻ります。")
            }
        }
    }
    
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
}

private struct SettingsSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.white.opacity(0.6))
                .padding(.horizontal, 4)
            
            content
                .background {
                    if #available(iOS 26, *) {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(.clear)
                            .glassEffect(in: .rect(cornerRadius: 16))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .strokeBorder(.white.opacity(0.15), lineWidth: 1)
                            )
                    } else {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(.white.opacity(0.08))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .strokeBorder(.white.opacity(0.1), lineWidth: 1)
                            )
                    }
                }
        }
    }
}

private struct BackgroundGradient: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color(red: 0.2, green: 0.1, blue: 0.3),
                Color(red: 0.1, green: 0.2, blue: 0.4)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

#Preview {
    SettingsView(
        settingsManager: SettingsManager(),
        favoritesManager: FavoritesManager()
    )
    .environment(NotificationManager())
}

