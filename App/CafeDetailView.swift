import SwiftUI
import DokoCafeFeature
import CafeDokoCore

struct CafeDetailView: View {
    let chain: DokoCafeViewModel.Chain
    let descriptor: CafeImageDescriptor
    let favoritesManager: FavoritesManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicType
    @Environment(ChainMenuManager.self) private var chainMenuManager
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // ヘッダー画像
                CafeHeaderImage(descriptor: descriptor)
                
                // 基本情報
                VStack(alignment: .leading, spacing: 16) {
                    // 店名と距離
                    VStack(alignment: .leading, spacing: 8) {
                        Text(chain.name)
                            .font(.title.bold())
                            .foregroundStyle(.white)
                        
                        HStack(spacing: 12) {
                            Label("\(chain.distance)m", systemImage: "figure.walk")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            
                            if let updatedAt = chain.updatedAt {
                                HStack(spacing: 4) {
                                    Image(systemName: "calendar")
                                    Text(updatedAt, format: .dateTime.month().day())
                                }
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            }
                        }
                    }
                    
                    Divider()
                        .background(.white.opacity(0.2))
                    
                    // 価格情報
                    HStack(alignment: .firstTextBaseline) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("価格")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            HStack(alignment: .firstTextBaseline, spacing: 4) {
                                Text("¥\(chain.price)")
                                    .font(.system(size: 42, weight: .heavy, design: .rounded))
                                    .foregroundStyle(.white)
                                Text(chain.sizeLabel)
                                    .font(.title3)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("徒歩時間")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("\(estimatedWalkingTime)分")
                                .font(.title2.bold())
                                .foregroundStyle(.white)
                        }
                    }
                    .padding()
                    .background {
                        if #available(iOS 26, *) {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(.clear)
                                .glassEffect(in: .rect(cornerRadius: 16))
                        } else {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(.white.opacity(0.08))
                        }
                    }
                    
                    // タグ
                    if !chain.tags.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("特徴")
                                .font(.headline)
                                .foregroundStyle(.white)
                            
                            FlowLayout(spacing: 8) {
                                ForEach(chain.tags, id: \.self) { tag in
                                    TagChip(tag: tag)
                                }
                            }
                        }
                    }
                    
                    // チェーン店メニュー
                    if let detectedChain = chainMenuManager.detectChain(from: chain.name) {
                        ChainMenuSection(chain: detectedChain)
                    }
                    
                    // 営業時間
                    if let hours = chain.openingHours {
                        InfoSection(
                            title: "営業時間",
                            icon: "clock.fill",
                            content: hours,
                            badge: isOpen ? "営業中" : "閉店中",
                            badgeColor: isOpen ? .green : .gray
                        )
                    }
                    
                    // 住所
                    if let address = chain.address {
                        InfoSection(
                            title: "住所",
                            icon: "mappin.circle.fill",
                            content: address,
                            action: {
                                openAddressInMaps()
                            }
                        )
                    }
                    
                    // 電話番号
                    if let phone = chain.phoneNumber {
                        InfoSection(
                            title: "電話番号",
                            icon: "phone.fill",
                            content: phone,
                            action: {
                                callPhoneNumber()
                            }
                        )
                    }
                    
                    // アクションボタン
                    VStack(spacing: 12) {
                        Button {
                                openInMaps()
                        } label: {
                            Label("マップで開く", systemImage: "map.fill")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                        }
                        .buttonStyle(iOS26ButtonStyle())
                        .tint(.blue)
                        
                        HStack(spacing: 12) {
                            Button {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    favoritesManager.toggleFavorite(chain.id)
                                }
                            } label: {
                                Label(
                                    favoritesManager.isFavorite(chain.id) ? "保存済み" : "保存",
                                    systemImage: favoritesManager.isFavorite(chain.id) ? "heart.fill" : "heart"
                                )
                                .frame(maxWidth: .infinity)
                                .contentTransition(.symbolEffect(.replace))
                            }
                            .buttonStyle(.bordered)
                            .tint(favoritesManager.isFavorite(chain.id) ? .red : .white.opacity(0.3))
                            
                            Button {
                                shareChain()
                            } label: {
                                Label("共有", systemImage: "square.and.arrow.up")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .tint(.white.opacity(0.3))
                        }
                    }
                }
                .padding(.horizontal, 24)
            }
            .padding(.bottom, 32)
        }
        .background(BackgroundGradient())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.white.opacity(0.7))
                        .imageScale(.large)
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var estimatedWalkingTime: Int {
        // 徒歩速度を約80m/分として計算
        Int(ceil(Double(chain.distance) / 80.0))
    }
    
    private var isOpen: Bool {
        BusinessHoursParser.isOpen(hoursString: chain.openingHours)
    }
    
    // MARK: - Actions
    
    private func openInMaps() {
        // 住所が利用可能な場合は住所で検索、将来的に座標データが追加されればそちらを優先
        if chain.address != nil {
            openAddressInMaps()
        } else {
            // 座標がない場合はカフェ名で検索
            let encodedName = chain.name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            if let url = URL(string: "http://maps.apple.com/?q=\(encodedName)") {
                UIApplication.shared.open(url)
            }
        }
    }
    
    private func openAddressInMaps() {
        guard let address = chain.address else { return }
        let encodedAddress = address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: "http://maps.apple.com/?q=\(encodedAddress)") {
            UIApplication.shared.open(url)
        }
    }
    
    private func callPhoneNumber() {
        guard let phone = chain.phoneNumber else { return }
        let cleanPhone = phone.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        if let url = URL(string: "tel:\(cleanPhone)") {
            UIApplication.shared.open(url)
        }
    }
    
    private func shareChain() {
        var shareText = """
        📍 \(chain.name)
        💰 ¥\(chain.price) (\(chain.sizeLabel))
        📏 \(chain.distance)m
        """
        
        if !chain.tags.isEmpty {
            shareText += "\n🏷️ \(chain.tags.joined(separator: ", "))"
        }
        
        if let address = chain.address {
            shareText += "\n🗺️ \(address)"
        }
        
        if let hours = chain.openingHours {
            shareText += "\n🕐 \(hours)"
        }
        
        let activityVC = UIActivityViewController(
            activityItems: [shareText],
            applicationActivities: nil
        )
        
        // iPad対応: ポップオーバー表示の設定
        if let popover = activityVC.popoverPresentationController {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                popover.sourceView = window
                popover.sourceRect = CGRect(x: window.bounds.midX, y: window.bounds.midY, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }
        }
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
}

// MARK: - Supporting Views

private struct CafeHeaderImage: View {
    let descriptor: CafeImageDescriptor
    
    var body: some View {
        ZStack {
            // 背景グラデーション
            LinearGradient(
                colors: [
                    Color.blue.opacity(0.3),
                    Color.purple.opacity(0.2)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // カフェ画像
            CafeImage(descriptor: descriptor)
                .frame(width: 120, height: 120)
        }
        .frame(height: 200)
        .frame(maxWidth: .infinity)
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
                .padding(24)
                .foregroundStyle(.white)
                .background(
                    Circle()
                        .fill(.white.opacity(0.15))
                )
        case .asset(let name):
            Image(name)
                .resizable()
                .scaledToFill()
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 2))
        case .remote(let url):
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .clipShape(Circle())
                case .failure, .empty:
                    Image(systemName: "cup.and.saucer")
                        .resizable()
                        .scaledToFit()
                        .padding(24)
                        .foregroundStyle(.white.opacity(0.7))
                        .background(
                            Circle()
                                .fill(.white.opacity(0.15))
                        )
                @unknown default:
                    EmptyView()
                }
            }
            .frame(width: 120, height: 120)
        }
    }
}

private struct TagChip: View {
    let tag: String
    
    var body: some View {
        Text(tag)
            .font(.subheadline.weight(.semibold))
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background(.white.opacity(0.15), in: Capsule())
            .foregroundStyle(.white)
    }
}

private struct InfoSection: View {
    let title: String
    let icon: String
    let content: String
    var badge: String? = nil
    var badgeColor: Color? = nil
    var action: (() -> Void)? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(title, systemImage: icon)
                    .font(.headline)
                    .foregroundStyle(.white)
                
                if let badge = badge, let badgeColor = badgeColor {
                    Text(badge)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(badgeColor.gradient)
                        )
                }
            }
            
            if let action = action {
                Button(action: action) {
                    HStack {
                        Text(content)
                            .font(.body)
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.leading)
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                            .foregroundStyle(.blue)
                    }
                    .padding()
                    .background {
                        if #available(iOS 26, *) {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(.clear)
                                .glassEffect(in: .rect(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .strokeBorder(.white.opacity(0.15), lineWidth: 1)
                                )
                        } else {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(.white.opacity(0.08))
                        }
                    }
                }
                .buttonStyle(.plain)
            } else {
                Text(content)
                    .font(.body)
                    .foregroundStyle(.white)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background {
                        if #available(iOS 26, *) {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(.clear)
                                .glassEffect(in: .rect(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .strokeBorder(.white.opacity(0.15), lineWidth: 1)
                                )
                        } else {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(.white.opacity(0.08))
                        }
                    }
            }
        }
    }
}

private struct BackgroundGradient: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color(red: 15/255, green: 23/255, blue: 42/255),
                Color(red: 30/255, green: 41/255, blue: 59/255)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

// MARK: - Flow Layout

private struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(at: result.positions[index], proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var lineHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += lineHeight + spacing
                    lineHeight = 0
                }
                
                positions.append(CGPoint(x: x, y: y))
                lineHeight = max(lineHeight, size.height)
                x += size.width + spacing
            }
            
            self.size = CGSize(
                width: maxWidth,
                height: y + lineHeight
            )
        }
    }
}

// MARK: - Chain Menu Section

private struct ChainMenuSection: View {
    let chain: ChainMenuManager.Chain
    @State private var expandedCategories: Set<String> = []
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "cup.and.saucer.fill")
                    .font(.title2)
                    .foregroundStyle(.orange)
                
                Text("メニュー")
                    .font(.headline)
                    .foregroundStyle(.white)
            }
            
            VStack(spacing: 12) {
                ForEach(Array(Set(chain.products.map { $0.category })).sorted(), id: \.self) { category in
                    VStack(alignment: .leading, spacing: 8) {
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                if expandedCategories.contains(category) {
                                    expandedCategories.remove(category)
                                } else {
                                    expandedCategories.insert(category)
                                }
                            }
                        } label: {
                            HStack {
                                Text(category)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.white)
                                Spacer()
                                Image(systemName: expandedCategories.contains(category) ? "chevron.up" : "chevron.down")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.6))
                            }
                            .padding(.vertical, 8)
                        }
                        .buttonStyle(.plain)
                        
                        if expandedCategories.contains(category) {
                            VStack(spacing: 6) {
                                ForEach(chain.products.filter { $0.category == category }) { product in
                                    HStack {
                                        Text(product.name)
                                            .font(.footnote)
                                            .foregroundStyle(.white.opacity(0.9))
                                        Spacer()
                                        Text(formatPrices(product.sizes))
                                            .font(.footnote.weight(.medium))
                                            .foregroundStyle(.white.opacity(0.8))
                                    }
                                    .padding(.vertical, 4)
                                    .padding(.leading, 12)
                                }
                            }
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                    
                    if category != Array(Set(chain.products.map { $0.category })).sorted().last {
                        Divider()
                            .background(.white.opacity(0.1))
                    }
                }
            }
        }
        .padding()
        .background {
            if #available(iOS 26, *) {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.clear)
                    .glassEffect(in: .rect(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(.white.opacity(0.2), lineWidth: 1)
                    )
            } else {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.white.opacity(0.15))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(.white.opacity(0.2), lineWidth: 1)
                    )
            }
        }
        .onAppear {
            // デフォルトで最初のカテゴリを展開
            if let firstCategory = Set(chain.products.map { $0.category }).sorted().first {
                expandedCategories.insert(firstCategory)
            }
        }
    }
    
    private func formatPrices(_ sizes: [ChainMenuManager.Size]) -> String {
        if sizes.count == 1 {
            return "¥\(sizes[0].price)"
        } else {
            let minPrice = sizes.map { $0.price }.min() ?? 0
            let maxPrice = sizes.map { $0.price }.max() ?? 0
            return "¥\(minPrice)〜¥\(maxPrice)"
        }
    }
}

// MARK: - iOS 26 Button Style

private struct iOS26ButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        if #available(iOS 26, *) {
            configuration.label
                .buttonStyle(.glass)
        } else {
            configuration.label
                .buttonStyle(.borderedProminent)
        }
    }
}

#Preview {
    CafeDetailView(
        chain: DokoCafeViewModel.Chain(
            name: "スターバックス 渋谷店",
            price: 450,
            sizeLabel: "Tall",
            distance: 250,
            tags: ["WiFi", "電源", "禁煙"],
            address: "東京都渋谷区道玄坂2-1-1",
            openingHours: "7:00 - 23:00",
            phoneNumber: "03-1234-5678"
        ),
        descriptor: .systemSymbol("cup.and.saucer.fill"),
        favoritesManager: FavoritesManager()
    )
    .environment(ChainMenuManager())
}

