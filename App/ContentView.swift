import SwiftUI
import CafeDokoCore
import DokoCafeFeature

enum ViewMode {
    case list
    case map
}

struct ContentView: View {
    @Environment(RootAppModel.self) private var projectModel
    @Environment(DokoCafeViewModel.self) private var cafeModel
    @Environment(FavoritesManager.self) private var favoritesManager
    @Environment(HistoryManager.self) private var historyManager
    @Environment(SettingsManager.self) private var settingsManager
    @State private var searchQuery = ""
    @State private var selectedSort: SortOption = .recommended
    @State private var selectedChain: DokoCafeViewModel.Chain?
    @State private var showingDetail = false
    @State private var showFavoritesOnly = false
    @State private var showingSettings = false
    @State private var showingHelp = false
    @State private var showingHistory = false
    @State private var showingFavoritesList = false
    
    // 設定から直接読み込むように変更
    private var viewMode: ViewMode {
        settingsManager.defaultViewMode == .list ? .list : .map
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // リストビュー
                if viewMode == .list {
                    ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Header()
                        CafeSearchBar(query: $searchQuery)
                        VStack(alignment: .leading, spacing: 12) {
                            ScrollView(.horizontal, showsIndicators: false) {
                                SortSelector(selected: $selectedSort)
                            }
                            FavoritesFilterButton(
                                isActive: $showFavoritesOnly,
                                count: favoritesManager.count
                            )
                        }
                        CafeCarousel(
                            chains: filteredChains(for: selectedSort),
                            favoritesManager: favoritesManager,
                            onChainTap: { chain in
                                selectedChain = chain
                                showingDetail = true
                            },
                            onDetailTap: { chain in
                                selectedChain = chain
                                showingDetail = true
                            }
                        )
                        QuickActions(
                            isLoading: cafeModel.isLoading,
                            hasError: cafeModel.lastErrorMessage != nil,
                            reload: {
                                Task { await cafeModel.reload() }
                            },
                            onHistoryTap: {
                                showingHistory = true
                            },
                            onFavoritesTap: {
                                showingFavoritesList = true
                            }
                        )
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                    .accessibilityIdentifier("CafeListScrollView")
                    }
                }
                
                // マップビュー
                if viewMode == .map {
                    CafeMapView(
                        chains: filteredChains(for: selectedSort),
                        onChainTap: { chain in
                            selectedChain = chain
                            showingDetail = true
                        }
                    )
                }
                
                if cafeModel.isLoading {
                    LoadingOverlay()
                        .transition(.opacity.combined(with: .scale))
                        .accessibilityAddTraits(.isModal)
                }
            }
            .background(BackgroundGradient())
            .overlay(alignment: .top) {
                if let message = cafeModel.lastErrorMessage {
                    ErrorBanner(
                        message: message,
                        suggestion: errorSuggestion(from: message),
                        retry: {
                            Task { await cafeModel.reload() }
                        },
                        dismiss: {
                            cafeModel.clearError()
                        }
                    )
                    .padding(.top, 12)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .navigationTitle("カフェどこ？")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    viewModeToggle
                }
                automationMenu
            }
            .sheet(isPresented: $showingDetail) {
                if let chain = selectedChain {
                    NavigationStack {
                        CafeDetailView(
                            chain: chain,
                            descriptor: cafeModel.imageDescriptor(for: chain),
                            favoritesManager: favoritesManager
                        )
                        .onAppear {
                            historyManager.addEntry(cafeID: chain.id, cafeName: chain.name)
                        }
                    }
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView(
                    settingsManager: settingsManager,
                    favoritesManager: favoritesManager
                )
            }
            .sheet(isPresented: $showingHelp) {
                HelpView()
            }
            .sheet(isPresented: $showingHistory) {
                HistoryView()
            }
            .sheet(isPresented: $showingFavoritesList) {
                FavoritesListView()
            }
            .onAppear {
                // 設定から初期ソート順を読み込む
                selectedSort = convertToSortOption(settingsManager.defaultSortOption)
            }
        }
    }
    
    // SettingsManager.SortOption を SortOption に変換
    private func convertToSortOption(_ option: SettingsManager.SortOption) -> SortOption {
        switch option {
        case .recommended: return .recommended
        case .nearby: return .nearby
        case .priceLow: return .price
        }
    }

    private var viewModeToggle: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.3)) {
                // 設定を直接更新
                settingsManager.defaultViewMode = viewMode == .list ? .map : .list
            }
        } label: {
            Image(systemName: viewMode == .list ? "map.fill" : "list.bullet")
                .imageScale(.large)
        }
        .accessibilityLabel(viewMode == .list ? "地図表示に切り替え" : "リスト表示に切り替え")
    }
    
    private var automationMenu: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Button("設定", action: openSettings)
                Button("ヘルプ", action: openHelp)
            } label: {
                Image(systemName: "line.3.horizontal")
                    .imageScale(.large)
            }
        }
    }

    private func filteredChains(for sort: SortOption) -> [DokoCafeViewModel.Chain] {
        var base = cafeModel.chains
        
        // 検索フィルタ
        if !searchQuery.isEmpty {
            base = base.filter { chain in
                let key = searchQuery.lowercased()
                return chain.name.lowercased().contains(key) ||
                    chain.tags.contains { $0.lowercased().contains(key) }
            }
        }
        
        // お気に入りフィルタ
        if showFavoritesOnly {
            base = base.filter { favoritesManager.isFavorite($0.id) }
        }

        // ソート
        switch sort {
        case .recommended:
            return base
        case .nearby:
            return base.sorted { $0.distance < $1.distance }
        case .price:
            return base.sorted { $0.price < $1.price }
        }
    }
    
    private func errorSuggestion(from message: String) -> String? {
        // エラーメッセージから適切な対処法を推測
        if message.contains("インターネット") || message.contains("ネットワーク") {
            return "インターネット接続を確認してください。"
        } else if message.contains("タイムアウト") {
            return "接続がタイムアウトしました。ネットワーク環境を確認して再試行してください。"
        } else if message.contains("サーバーエラー") {
            if message.contains("50") {
                return "サーバーが一時的に利用できません。しばらく待ってから再試行してください。"
            } else if message.contains("401") || message.contains("403") {
                return "認証に失敗しました。アプリを再起動してください。"
            }
        } else if message.contains("解釈") || message.contains("デコード") {
            return "データ形式が変更された可能性があります。アプリを最新版に更新してください。"
        }
        return "しばらく待ってから再度お試しください。問題が続く場合はサポートにお問い合わせください。"
    }

    private func openSettings() {
        showingSettings = true
    }
    
    private func openHelp() {
        showingHelp = true
    }
}

private struct BackgroundGradient: View {
    var body: some View {
        LinearGradient(
            colors: [Color(red: 15/255, green: 23/255, blue: 42/255), Color(red: 30/255, green: 41/255, blue: 59/255)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

private struct ErrorBanner: View {
    let message: String
    let suggestion: String?
    let retry: () -> Void
    let dismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundStyle(.white)
                    .imageScale(.large)
                    .accessibilityHidden(true)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(message)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.leading)
                        .lineLimit(nil)
                    
                    if let suggestion {
                        Text(suggestion)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.8))
                            .multilineTextAlignment(.leading)
                            .lineLimit(nil)
                    }
                }
                
                Spacer()
                
                Button(action: retry) {
                    Label("再試行", systemImage: "arrow.clockwise")
                        .labelStyle(.iconOnly)
                        .padding(8)
                        .background(Circle().fill(Color.white.opacity(0.2)))
                        .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("再試行")
                
                Button(action: dismiss) {
                    Image(systemName: "xmark")
                        .foregroundStyle(.white.opacity(0.7))
                        .padding(8)
                        .background(Circle().fill(Color.white.opacity(0.15)))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("閉じる")
            }
        }
        .padding(14)
        .background(.red.opacity(0.85), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding(.horizontal, 24)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("エラー: \(message)")
        .accessibilityHint("再試行または閉じるボタンを選択")
    }
}

private struct LoadingOverlay: View {
    @Environment(\.dynamicTypeSize) private var dynamicType

    var body: some View {
        VStack(spacing: 12) {
            ProgressView()
                .progressViewStyle(.circular)
                .scaleEffect(dynamicType >= .accessibility1 ? 1.4 : 1.0)
            Text("読み込み中…")
                .font(dynamicType >= .accessibility1 ? .title3.weight(.semibold) : .body.weight(.semibold))
                .foregroundStyle(.primary)
        }
        .padding(dynamicType >= .accessibility1 ? 32 : 24)
        .background {
            if #available(iOS 26, *) {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(.clear)
                    .glassEffect(in: .rect(cornerRadius: 24))
            } else {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(.ultraThinMaterial)
            }
        }
        .padding()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("読み込み中")
    }
}

private struct Header: View {
    @State private var currentFact: String = ""
    @State private var cafeFacts: [String] = []
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if !currentFact.isEmpty {
                Text(currentFact)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
                    .lineLimit(2)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
            
            Text("今日はどこのカフェ？")
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(2, reservesSpace: true)
        }
        .onAppear {
            loadCafeFacts()
            updateFact()
            startFactRotation()
        }
    }
    
    private func loadCafeFacts() {
        guard let url = Bundle.main.url(forResource: "CafeFacts", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let facts = try? JSONDecoder().decode([String].self, from: data) else {
            cafeFacts = ["今日も素敵なカフェタイムを！"]
            return
        }
        cafeFacts = facts
    }
    
    private func updateFact() {
        guard !cafeFacts.isEmpty else { return }
        withAnimation(.easeInOut(duration: 0.5)) {
            currentFact = cafeFacts.randomElement() ?? ""
        }
    }
    
    private func startFactRotation() {
        Timer.scheduledTimer(withTimeInterval: 8.0, repeats: true) { _ in
            updateFact()
        }
    }
}

private struct CafeSearchBar: View {
    @Binding var query: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass.circle.fill")
                .font(.title3)
                .foregroundStyle(.tint)
            TextField("メニューや条件で検索", text: $query)
                .textFieldStyle(.plain)
                .foregroundStyle(.white)
                .tint(.white)
                .accessibilityLabel("カフェ検索")
                .accessibilityHint("店名や設備で絞り込み")
            
            if !query.isEmpty {
                Button {
                    query = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .accessibilityLabel("検索をクリア")
            }
        }
        .padding(18)
        .background {
            if #available(iOS 26, *) {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(.clear)
                    .glassEffect(in: .rect(cornerRadius: 24))
            } else {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .strokeBorder(.white.opacity(0.08), lineWidth: 1)
                    )
            }
        }
    }
}

private enum SortOption: String, CaseIterable, Identifiable {
    case recommended = "おすすめ"
    case nearby = "近い順"
    case price = "価格が安い順"

    var id: String { rawValue }
}

private struct FavoritesFilterButton: View {
    @Binding var isActive: Bool
    let count: Int
    
    var body: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isActive.toggle()
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: isActive ? "heart.fill" : "heart")
                    .font(.footnote.weight(.semibold))
                    .symbolEffect(.bounce, value: isActive)
                Text(isActive ? "お気に入りのみ表示中" : "お気に入りで絞り込み")
                    .font(.footnote.weight(.semibold))
                if count > 0 {
                    Text("(\(count))")
                        .font(.footnote.weight(.bold))
                }
                Spacer()
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background {
                if #available(iOS 26, *) {
                    if isActive {
                        Capsule()
                            .fill(Color.red)
                    } else {
                        Capsule()
                            .fill(.clear)
                            .glassEffect(in: .capsule)
                            .overlay(
                                Capsule()
                                    .strokeBorder(.white.opacity(0.2), lineWidth: 1)
                            )
                    }
                } else {
                    Capsule()
                        .fill(isActive ? Color.red : Color.white.opacity(0.12))
                }
            }
            .foregroundStyle(isActive ? .white : .secondary)
        }
        .accessibilityLabel(isActive ? "お気に入りのみ表示中" : "お気に入りのみ表示")
    }
}

private struct SortSelector: View {
    @Binding var selected: SortOption

    var body: some View {
        HStack(spacing: 8) {
            ForEach(SortOption.allCases) { option in
                Button {
                    selected = option
                } label: {
                    Text(option.rawValue)
                        .font(.footnote.weight(.semibold))
                        .padding(.vertical, 10)
                        .padding(.horizontal, 16)
                        .background {
                            if #available(iOS 26, *) {
                                if selected == option {
                                    Capsule()
                                        .fill(.clear)
                                        .glassEffect(in: .capsule)
                                        .overlay(
                                            Capsule()
                                                .strokeBorder(.white.opacity(0.3), lineWidth: 1)
                                        )
                                } else {
                                    Capsule()
                                        .fill(.white.opacity(0.08))
                                        .overlay(
                                            Capsule()
                                                .strokeBorder(.white.opacity(0.15), lineWidth: 1)
                                        )
                                }
                            } else {
                                Capsule()
                                    .fill(selected == option ? Color.white.opacity(0.2) : Color.white.opacity(0.05))
                                    .overlay(
                                        Capsule()
                                            .stroke(.white.opacity(selected == option ? 0.4 : 0.15), lineWidth: 1)
                                    )
                            }
                        }
                        .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(option.rawValue)
                .accessibilityHint("並べ替え")
            }
        }
    }
}

private struct CafeCarousel: View {
    let chains: [DokoCafeViewModel.Chain]
    let favoritesManager: FavoritesManager
    let onChainTap: (DokoCafeViewModel.Chain) -> Void
    let onDetailTap: (DokoCafeViewModel.Chain) -> Void
    @Environment(DokoCafeViewModel.self) private var viewModel

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 20) {
                if chains.isEmpty {
                    EmptyStateCard()
                } else {
                    ForEach(Array(chains.enumerated()), id: \.element.id) { index, chain in
                        CafeChainCard(
                            chain: chain,
                            descriptor: viewModel.imageDescriptor(for: chain),
                            favoritesManager: favoritesManager,
                            onDetailTap: {
                                onDetailTap(chain)
                            }
                        )
                        .onTapGesture {
                            onChainTap(chain)
                        }
                        .transition(.asymmetric(
                            insertion: .scale.combined(with: .opacity),
                            removal: .opacity
                        ))
                        .animation(
                            .spring(response: 0.4, dampingFraction: 0.8)
                                .delay(Double(index) * 0.1),
                            value: chains.count
                        )
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }
}

private struct EmptyStateCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .font(.title2)
                    .foregroundStyle(.white.opacity(0.6))
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("該当するカフェが")
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text("見つかりません")
                        .font(.headline)
                        .foregroundStyle(.white)
                }
            }
            Text("検索条件を調整するか、\n再読み込みしてください。")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(width: 340, alignment: .leading)
        .padding(24)
        .background {
            if #available(iOS 26, *) {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(.clear)
                    .glassEffect(in: .rect(cornerRadius: 28))
                    .overlay(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .strokeBorder(.white.opacity(0.15), lineWidth: 1)
                    )
            } else {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(.white.opacity(0.12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .strokeBorder(.white.opacity(0.2), lineWidth: 1)
                    )
            }
        }
    }
}

private struct CafeChainCard: View {
    let chain: DokoCafeViewModel.Chain
    let descriptor: CafeImageDescriptor
    let favoritesManager: FavoritesManager
    let onDetailTap: () -> Void
    @State private var isPressed = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center, spacing: 12) {
                CafeImage(descriptor: descriptor)
                    .frame(width: 44, height: 44)
                VStack(alignment: .leading, spacing: 4) {
                    Text(chain.name)
                        .font(.headline)
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .accessibilityLabel(chain.name)
                    Text("徒歩約\(chain.distance)m")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .accessibilityLabel("徒歩約\(chain.distance)メートル")
                }
                Spacer()
                FavoriteButton(
                    isFavorite: favoritesManager.isFavorite(chain.id),
                    action: {
                        favoritesManager.toggleFavorite(chain.id)
                    }
                )
            }

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("¥\(chain.price)")
                    .font(.system(size: 32, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .accessibilityLabel("価格\(chain.price)円")
                Text(chain.sizeLabel)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Button(action: onDetailTap) {
                    Label("詳細", systemImage: "arrow.right.circle.fill")
                        .font(.subheadline.weight(.semibold))
                }
                .labelStyle(.titleAndIcon)
                .buttonStyle(.borderedProminent)
                .tint(.white.opacity(0.2))
                .accessibilityLabel("詳細を開く")
            }

            HStack(spacing: 8) {
                ForEach(chain.tags, id: \.self) { tag in
                    Text(tag)
                        .font(.caption.weight(.semibold))
                        .padding(.vertical, 6)
                        .padding(.horizontal, 12)
                        .background(.white.opacity(0.12), in: Capsule())
                        .foregroundStyle(.white)
                        .accessibilityLabel(tag)
                }
            }

            if let updatedAt = chain.updatedAt {
                Text(updatedAt, format: .dateTime.year().month().day())
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .accessibilityLabel("更新日\(updatedAt.formatted(date: .abbreviated, time: .omitted))")
            }
        }
        .padding(20)
        .frame(width: 280, alignment: .leading)
        .background {
            if #available(iOS 26, *) {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(.clear)
                    .glassEffect(in: .rect(cornerRadius: 28))
            } else {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
            }
        }
        .shadow(color: .black.opacity(0.25), radius: 18, x: 0, y: 12)
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("CafeChainCard_\(chain.id.uuidString)")
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

private struct CafeImage: View {
    let descriptor: CafeImageDescriptor

    var body: some View {
        switch descriptor {
        case .systemSymbol(let name):
            Image(systemName: name)
                .resizable()
                .scaledToFit()
                .padding(10)
                .foregroundStyle(.white)
                .background(
                    Circle()
                        .fill(Color.white.opacity(0.15))
                )
        case .asset(let name):
            Image(name)
                .resizable()
                .scaledToFill()
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.white.opacity(0.1), lineWidth: 1))
        case .remote(let url):
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                case .failure:
                    Image(systemName: "cup.and.saucer")
                        .resizable()
                        .scaledToFit()
                        .padding(10)
                        .foregroundStyle(.white.opacity(0.7))
                case .empty:
                    ProgressView()
                @unknown default:
                    EmptyView()
                }
            }
            .clipShape(Circle())
            .overlay(Circle().stroke(Color.white.opacity(0.1), lineWidth: 1))
            .background(Circle().fill(Color.white.opacity(0.08)))
        }
    }
}

private struct FavoriteButton: View {
    let isFavorite: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: isFavorite ? "heart.fill" : "heart")
                .font(.title3)
                .foregroundStyle(isFavorite ? .red : .white)
                .contentTransition(.symbolEffect(.replace))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isFavorite ? "お気に入りから削除" : "お気に入りに追加")
    }
}

private struct QuickActions: View {
    let isLoading: Bool
    let hasError: Bool
    let reload: () -> Void
    let onHistoryTap: () -> Void
    let onFavoritesTap: () -> Void
    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(spacing: 16) {
            Button {
                openMapsApp()
            } label: {
                Label("経路をマップで確認", systemImage: "map.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
            .background {
                if #available(iOS 26, *) {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(.clear)
                        .glassEffect(in: .rect(cornerRadius: 22))
                        .overlay(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .strokeBorder(.white.opacity(0.2), lineWidth: 1)
                        )
                } else {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(.white.opacity(0.2))
                }
            }
            .foregroundStyle(.white)
            .disabled(isLoading)
            .accessibilityHint("地図アプリを開いて経路を確認")

            HStack(spacing: 16) {
                LinkButton(title: "履歴を見る", systemImage: "clock.arrow.circlepath", disabled: isLoading, action: onHistoryTap)
                LinkButton(title: "お気に入り", systemImage: "heart", disabled: isLoading, action: onFavoritesTap)
            }

            if hasError || !isLoading {
                Button(action: reload) {
                    Label("再読み込み", systemImage: "arrow.clockwise")
                        .font(.footnote.weight(.semibold))
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                }
                .background {
                    if #available(iOS 26, *) {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(.clear)
                            .glassEffect(in: .rect(cornerRadius: 18))
                            .overlay(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .strokeBorder(hasError ? .red.opacity(0.5) : .white.opacity(0.2), lineWidth: 1)
                            )
                    } else {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(hasError ? .red.opacity(0.5) : .white.opacity(0.25))
                    }
                }
                .foregroundStyle(.white)
                .disabled(isLoading)
                .accessibilityHint("最新のカフェ情報を取得")
            }
        }
    }
    
    private func openMapsApp() {
        // 現在地周辺のカフェを検索
        if let url = URL(string: "http://maps.apple.com/?q=カフェ") {
            openURL(url)
        }
    }
}

private struct LinkButton: View {
    let title: String
    let systemImage: String
    let disabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.subheadline.weight(.medium))
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
        }
        .background {
            if #available(iOS 26, *) {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(.clear)
                    .glassEffect(in: .rect(cornerRadius: 18))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .strokeBorder(.white.opacity(0.2), lineWidth: 1)
                    )
            } else {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(.white.opacity(0.2))
            }
        }
        .foregroundStyle(.white)
        .disabled(disabled)
        .accessibilityHint(disabled ? "読み込み中は利用できません" : "機能を開く")
    }
}

#Preview("Main View") {
    ContentView()
        .environment(RootAppModel(milestones: .sample()))
        .environment(DokoCafeViewModel(dataProvider: EmptyCafeDataProvider(), imageProvider: SymbolCafeImageProvider()))
        .environment(FavoritesManager())
        .environment(HistoryManager())
        .environment(SettingsManager())
        .environment(ChainMenuManager())
        .environment(LocationManager())
        .environment(NotificationManager())
}
