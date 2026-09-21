import SwiftUI

struct HistoryView: View {
    @Environment(MenuStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var confirmClear = false

    private static let dateStyle = Date.FormatStyle()
        .day().month(.abbreviated).hour().minute()
        .locale(Locale(identifier: "th_TH"))

    var body: some View {
        NavigationStack {
            Group {
                if store.history.isEmpty {
                    ContentUnavailableView("ยังไม่มีประวัติ", systemImage: "clock",
                                           description: Text("สุ่มเมนูแล้วจะมาแสดงที่นี่"))
                } else {
                    List {
                        ForEach(store.history) { entry in
                            HStack(spacing: 12) {
                                Text(entry.food.emoji).font(.title2)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(entry.food.name).font(.body.weight(.medium))
                                    Text(entry.food.tag)
                                        .font(.caption)
                                        .foregroundStyle(Color.ink.opacity(0.6))
                                }
                                Spacer()
                                Text(entry.date.formatted(Self.dateStyle))
                                    .font(.caption)
                                    .foregroundStyle(Color.ink.opacity(0.6))
                            }
                        }
                        .onDelete { store.history.remove(atOffsets: $0) }
                    }
                }
            }
            .navigationTitle("ประวัติการสุ่ม")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if !store.history.isEmpty {
                        Button("ล้างทั้งหมด", role: .destructive) { confirmClear = true }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("เสร็จ") { dismiss() }
                }
            }
            .confirmationDialog("ลบประวัติทั้งหมด?", isPresented: $confirmClear, titleVisibility: .visible) {
                Button("ลบทั้งหมด", role: .destructive) { store.history.removeAll() }
            }
        }
        .tint(Color.ink)
    }
}
