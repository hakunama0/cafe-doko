import SwiftUI
import CafeDokoCore
import DokoCafeFeature

struct FavoritesListView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(FavoritesManager.self) var favoritesManager
    @Environment(DokoCafeViewModel.self) var cafeModel
    
    private var favoriteChains: [DokoCafeViewModel.Chain] {
        cafeModel.chains.filter { favoritesManager.isFavorite($0.id) }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                BackgroundGradient()
                    .ignoresSafeArea()
                
                if favoriteChains.isEmpty {
                    EmptyFavoritesView()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(favoriteChains) { chain in
                                FavoriteRow(chain: chain) {
                                    withAnimation {
                                        favoritesManager.removeFavorite(chain.id)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 16)
                    }
                }
            }
            .navigationTitle("お気に入り")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("閉じる") {
                        dismiss()
                    }
                    .foregroundStyle(.white)
                }
            }
        }
    }
}

private struct FavoriteRow: View {
    let chain: DokoCafeViewModel.Chain
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text(chain.name)
                    .font(.headline)
                    .foregroundStyle(.white)
                
                HStack(spacing: 12) {
                    Label("\(chain.distance)m", systemImage: "location.fill")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                    
                    Label("¥\(chain.price)", systemImage: "yensign.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                }
                
                if !chain.tags.isEmpty {
                    FlowLayout(spacing: 6) {
                        ForEach(chain.tags.prefix(3), id: \.self) { tag in
                            Text(tag)
                                .font(.caption2)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(.white.opacity(0.15))
                                )
                        }
                    }
                }
            }
            
            Spacer()
            
            Button(role: .destructive, action: onRemove) {
                Image(systemName: "heart.slash.fill")
                    .foregroundStyle(.red.opacity(0.8))
                    .font(.title3)
            }
            .buttonStyle(.plain)
        }
        .padding()
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

private struct EmptyFavoritesView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "heart")
                .font(.system(size: 60))
                .foregroundStyle(.white.opacity(0.4))
            
            Text("お気に入りがありません")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white)
            
            Text("気になるカフェを保存すると、ここに表示されます")
                .font(.body)
                .foregroundStyle(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
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
    }
}

// FlowLayout for tags
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
            subview.place(at: CGPoint(x: bounds.minX + result.frames[index].minX, y: bounds.minY + result.frames[index].minY), proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var frames: [CGRect] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if currentX + size.width > maxWidth && currentX > 0 {
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }
                
                frames.append(CGRect(origin: CGPoint(x: currentX, y: currentY), size: size))
                currentX += size.width + spacing
                lineHeight = max(lineHeight, size.height)
            }
            
            self.size = CGSize(width: maxWidth, height: currentY + lineHeight)
        }
    }
}

#Preview {
    FavoritesListView()
        .environment(FavoritesManager())
        .environment(DokoCafeViewModel(dataProvider: EmptyCafeDataProvider()))
}

