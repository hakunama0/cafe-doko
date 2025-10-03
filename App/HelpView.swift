import SwiftUI

struct HelpView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    HelpSection(
                        icon: "map.fill",
                        title: "地図とリストの切り替え",
                        description: "左上のボタンで地図表示とリスト表示を切り替えられます。地図ではピンをタップしてカフェの詳細を確認できます。"
                    )
                    
                    HelpSection(
                        icon: "heart.fill",
                        title: "お気に入り機能",
                        description: "カフェカードのハートアイコンをタップするとお気に入りに登録できます。フィルタボタンでお気に入りのみを表示できます。"
                    )
                    
                    HelpSection(
                        icon: "arrow.up.arrow.down",
                        title: "並べ替え",
                        description: "おすすめ順・近い順・価格が安い順で並べ替えができます。"
                    )
                    
                    HelpSection(
                        icon: "magnifyingglass",
                        title: "検索",
                        description: "検索バーからカフェ名やタグで絞り込みができます。"
                    )
                    
                    HelpSection(
                        icon: "clock.fill",
                        title: "営業時間",
                        description: "各カフェの詳細画面で営業時間を確認できます。営業中・閉店中のバッジがリアルタイムで表示されます。"
                    )
                    
                    HelpSection(
                        icon: "mappin.circle.fill",
                        title: "住所と連絡先",
                        description: "詳細画面の住所をタップすると地図アプリで開きます。電話番号をタップすると発信できます。"
                    )
                }
                .padding(24)
            }
            .background(BackgroundGradient())
            .navigationTitle("ヘルプ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
        }
    }
}

private struct HelpSection: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(.blue)
                
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.white)
            }
            
            Text(description)
                .font(.body)
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)
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
    }
}

private struct BackgroundGradient: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color(red: 0.06, green: 0.09, blue: 0.16),
                Color(red: 0.12, green: 0.16, blue: 0.23)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

#Preview {
    HelpView()
}

