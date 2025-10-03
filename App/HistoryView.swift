import SwiftUI
import CafeDokoCore

struct HistoryView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(HistoryManager.self) var historyManager
    
    var body: some View {
        NavigationStack {
            ZStack {
                BackgroundGradient()
                    .ignoresSafeArea()
                
                if historyManager.entries.isEmpty {
                    EmptyHistoryView()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(historyManager.entries) { entry in
                                HistoryRow(entry: entry) {
                                    historyManager.removeEntry(entry.id)
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 16)
                    }
                }
            }
            .navigationTitle("閲覧履歴")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("閉じる") {
                        dismiss()
                    }
                    .foregroundStyle(.white)
                }
                
                if !historyManager.entries.isEmpty {
                    ToolbarItem(placement: .topBarLeading) {
                        Button(role: .destructive) {
                            withAnimation {
                                historyManager.clearAll()
                            }
                        } label: {
                            Text("すべて削除")
                                .foregroundStyle(.red)
                        }
                    }
                }
            }
        }
    }
}

private struct HistoryRow: View {
    let entry: HistoryManager.HistoryEntry
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.cafeName)
                    .font(.headline)
                    .foregroundStyle(.white)
                
                Text(entry.viewedAt, style: .relative)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
            }
            
            Spacer()
            
            Button(role: .destructive, action: onDelete) {
                Image(systemName: "trash")
                    .foregroundStyle(.red.opacity(0.8))
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

private struct EmptyHistoryView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 60))
                .foregroundStyle(.white.opacity(0.4))
            
            Text("閲覧履歴がありません")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white)
            
            Text("カフェの詳細を見ると、ここに履歴が表示されます")
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

#Preview {
    HistoryView()
        .environment(HistoryManager())
}

