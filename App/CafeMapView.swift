import SwiftUI
import MapKit
import DokoCafeFeature

struct CafeMapView: View {
    let chains: [DokoCafeViewModel.Chain]
    let onChainTap: (DokoCafeViewModel.Chain) -> Void
    
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var selectedChain: DokoCafeViewModel.Chain?
    @State private var showCafeList = true
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Map(position: $cameraPosition, selection: $selectedChain) {
            // ユーザー位置（仮の東京駅周辺）
            Marker("現在地", systemImage: "location.fill", coordinate: CLLocationCoordinate2D(
                latitude: 35.6812,
                longitude: 139.7671
            ))
            .tint(.blue)
            
            // カフェのピン
            ForEach(chains) { chain in
                Marker(chain.name, systemImage: "cup.and.saucer.fill", coordinate: estimatedCoordinate(for: chain))
                    .tint(.orange)
                    .tag(chain)
            }
            }
            .mapStyle(.standard(elevation: .realistic))
            .mapControls {
                MapUserLocationButton()
                MapCompass()
                MapScaleView()
            }
            .onChange(of: selectedChain) { oldValue, newValue in
                if let chain = newValue {
                    onChainTap(chain)
                }
            }
            .onAppear {
                // 初期表示時に全てのカフェが見えるようにズーム
                updateCameraToShowAllCafes()
            }
            
            // リスト表示/非表示トグルボタン
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            showCafeList.toggle()
                        }
                    } label: {
                        Image(systemName: showCafeList ? "chevron.down.circle.fill" : "chevron.up.circle.fill")
                            .font(.title)
                            .foregroundStyle(.white)
                            .frame(width: 50, height: 50)
                    }
                    .background {
                        if #available(iOS 26, *) {
                            Circle()
                                .fill(.clear)
                                .glassEffect(in: .circle)
                                .overlay(
                                    Circle()
                                        .strokeBorder(.white.opacity(0.3), lineWidth: 2)
                                )
                        } else {
                            Circle()
                                .fill(.orange.opacity(0.9))
                                .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                                .overlay(
                                    Circle()
                                        .strokeBorder(.white.opacity(0.5), lineWidth: 2)
                                )
                        }
                    }
                    .padding(.trailing, 16)
                    .padding(.bottom, showCafeList ? 240 : 16)
                }
            }
            
            // カフェリストオーバーレイ
            if showCafeList {
                CafeListOverlay(chains: chains, onChainTap: onChainTap)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }
    
    // MARK: - Helper Methods
    
    /// カフェの座標を取得（実座標があればそれを使用、なければ距離から推定）
    private func estimatedCoordinate(for chain: DokoCafeViewModel.Chain) -> CLLocationCoordinate2D {
        // 実際の緯度経度がある場合はそれを使用
        if let latitude = chain.latitude, let longitude = chain.longitude {
            return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }
        
        // なければ距離から推定座標を生成
        // 仮の基準点（東京駅）
        let baseLatitude = 35.6812
        let baseLongitude = 139.7671
        
        // 距離をメートルから度に変換（大まかな計算）
        // 1度 ≈ 111km
        let distanceInDegrees = Double(chain.distance) / 111000.0
        
        // チェーンIDのハッシュから角度を決定（ランダムな方向）
        let angle = Double(abs(chain.id.hashValue)) * 0.01
        
        let latitude = baseLatitude + distanceInDegrees * cos(angle)
        let longitude = baseLongitude + distanceInDegrees * sin(angle)
        
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    /// 全てのカフェが見えるようにカメラ位置を調整
    private func updateCameraToShowAllCafes() {
        guard !chains.isEmpty else { return }
        
        let coordinates = chains.map { estimatedCoordinate(for: $0) }
        
        // 全座標の中心を計算
        let avgLatitude = coordinates.reduce(0.0) { $0 + $1.latitude } / Double(coordinates.count)
        let avgLongitude = coordinates.reduce(0.0) { $0 + $1.longitude } / Double(coordinates.count)
        
        // 範囲を計算
        let latitudes = coordinates.map { $0.latitude }
        let longitudes = coordinates.map { $0.longitude }
        
        let minLat = latitudes.min() ?? avgLatitude
        let maxLat = latitudes.max() ?? avgLatitude
        let minLon = longitudes.min() ?? avgLongitude
        let maxLon = longitudes.max() ?? avgLongitude
        
        let span = MKCoordinateSpan(
            latitudeDelta: (maxLat - minLat) * 1.5, // 余白を持たせる
            longitudeDelta: (maxLon - minLon) * 1.5
        )
        
        cameraPosition = .region(MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: avgLatitude, longitude: avgLongitude),
            span: span
        ))
    }
}

// MARK: - Cafe List Overlay

private struct CafeListOverlay: View {
    let chains: [DokoCafeViewModel.Chain]
    let onChainTap: (DokoCafeViewModel.Chain) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // ドラッグハンドル
            RoundedRectangle(cornerRadius: 2.5)
                .fill(.white.opacity(0.3))
                .frame(width: 40, height: 5)
                .padding(.top, 12)
            
            Text("\(chains.count)件のカフェ")
                .font(.headline)
                .foregroundStyle(.white)
                .padding(.top, 16)
                .padding(.bottom, 12)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(chains.prefix(10)) { chain in
                        CafeMapCard(chain: chain, onTap: {
                            onChainTap(chain)
                        })
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
            .frame(height: 160)
        }
        .frame(height: 220)
        .background {
            if #available(iOS 26, *) {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(.clear)
                    .glassEffect(in: .rect(cornerRadius: 20))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .strokeBorder(.white.opacity(0.2), lineWidth: 1)
                    )
                    .ignoresSafeArea(edges: .bottom)
            } else {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(.black.opacity(0.75))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .strokeBorder(.white.opacity(0.15), lineWidth: 1)
                    )
                    .ignoresSafeArea(edges: .bottom)
            }
        }
    }
}

private struct CafeMapCard: View {
    let chain: DokoCafeViewModel.Chain
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "cup.and.saucer.fill")
                        .foregroundStyle(.orange)
                        .font(.title3)
                    
                    Spacer()
                    
                    Text("¥\(chain.price)")
                        .font(.headline)
                        .foregroundStyle(.white)
                }
                
                Text(chain.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .lineLimit(2)
                
                HStack {
                    Image(systemName: "location.fill")
                        .font(.caption)
                    Text("\(chain.distance)m")
                        .font(.caption)
                }
                .foregroundStyle(.white.opacity(0.7))
                
                Spacer()
            }
            .padding(12)
            .frame(width: 140, height: 130)
        }
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
                    .fill(.white.opacity(0.12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(.white.opacity(0.1), lineWidth: 1)
                    )
            }
        }
    }
}

#Preview {
    CafeMapView(
        chains: [
            DokoCafeViewModel.Chain(
                name: "スターバックス",
                price: 420,
                sizeLabel: "トール",
                distance: 320,
                tags: ["Wi-Fi", "電源"]
            ),
            DokoCafeViewModel.Chain(
                name: "ドトールコーヒー",
                price: 360,
                sizeLabel: "M",
                distance: 120,
                tags: ["Wi-Fi"]
            )
        ],
        onChainTap: { _ in }
    )
}

