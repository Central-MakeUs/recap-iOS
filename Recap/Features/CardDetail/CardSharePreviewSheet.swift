import SwiftUI

struct CardSharePreviewSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(RecapCardStore.self) private var cardStore

    let cardID: InformationCard.ID

    private var card: InformationCard? { cardStore.card(id: cardID) }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 18) {
                if let card {
                    RecapScreenshotThumbnail(kind: card.collection, assetName: card.thumbnailAssetName)
                        .frame(height: 176)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                    VStack(alignment: .leading, spacing: 8) {
                        RecapCategoryPill(kind: card.collection, size: .regular)

                        Text(card.title)
                            .font(RecapFont.pretendard(size: 20, weight: .semibold))
                            .foregroundStyle(RecapTheme.ColorToken.textPrimary)

                        Text(card.summary)
                            .font(RecapFont.pretendard(size: 14, weight: .medium))
                            .foregroundStyle(RecapTheme.ColorToken.textSecondary)
                    }

                    ShareLink(
                        item: shareText(for: card),
                        preview: SharePreview(card.title)
                    ) {
                        Label("공유하기", systemImage: "square.and.arrow.up")
                            .font(RecapFont.pretendard(size: 16, weight: .semibold))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .tint(RecapTheme.ColorToken.primary)
                    .padding(.top, 8)
                } else {
                    MissingCardView(cardID: cardID)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(RecapTheme.ColorToken.background)
            .navigationTitle("공유")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("닫기", action: close)
                }
            }
        }
    }

    private func close() {
        dismiss()
    }

    private func shareText(for card: InformationCard) -> String {
        [
            card.title,
            card.summary,
            card.memo.isEmpty ? nil : card.memo,
            card.dateText
        ]
        .compactMap { $0 }
        .joined(separator: "\n\n")
    }
}

#Preview("정보카드 공유") {
    CardSharePreviewSheet(cardID: SampleData.cards[0].id)
        .environment(PreviewStores.recapCardStore())
}
