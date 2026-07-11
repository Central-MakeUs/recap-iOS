import SwiftUI

struct CardOriginalPreviewSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(RecapCardStore.self) private var cardStore

    let cardID: InformationCard.ID

    private var card: InformationCard? { cardStore.card(id: cardID) }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    RecapScreenshotThumbnail(
                        kind: card?.collection ?? .capture,
                        assetName: card?.thumbnailAssetName
                    )
                    .aspectRatio(9 / 14, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                    VStack(alignment: .leading, spacing: 8) {
                        Text(card?.title ?? "원본 이미지")
                            .font(RecapFont.pretendard(size: 20, weight: .semibold))
                            .foregroundStyle(RecapTheme.ColorToken.textPrimary)

                        if let card {
                            Text(card.dateText)
                                .font(RecapFont.pretendard(size: 13, weight: .medium))
                                .foregroundStyle(RecapTheme.ColorToken.textTertiary)
                        }
                    }
                }
                .padding(16)
            }
            .background(RecapTheme.ColorToken.background)
            .navigationTitle("원본 보기")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("닫기", action: close)
                }
            }
        }
    }

    private func close() { dismiss() }
}

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

    private func close() { dismiss() }

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

struct CollectionPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(RecapCardStore.self) private var cardStore

    let cardID: InformationCard.ID
    @State private var selectedCollection: CollectionKind

    init(cardID: InformationCard.ID, initialCollection: CollectionKind = .schedule) {
        self.cardID = cardID
        _selectedCollection = State(initialValue: initialCollection)
    }

    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(RecapTheme.ColorToken.border)
                .frame(width: 43, height: 5)
                .padding(.top, 16)
                .padding(.bottom, 17)

            VStack(alignment: .leading, spacing: 18) {
                Text("유형 변경")
                    .font(RecapFont.pretendard(size: 16, weight: .semibold))
                    .tracking(-0.32)
                    .foregroundStyle(RecapTheme.ColorToken.textPrimary)

                LazyVGrid(
                    columns: [GridItem(.fixed(140), spacing: 32), GridItem(.fixed(140))],
                    alignment: .leading,
                    spacing: 17
                ) {
                    ForEach(CollectionKind.allCases) { kind in
                        Button {
                            selectedCollection = kind
                        } label: {
                            CategoryPickerChip(
                                kind: kind,
                                isSelected: selectedCollection == kind
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .frame(width: 312, alignment: .leading)
                .padding(.leading, 16)

                RecapButton(title: "선택 완료", style: .primary, action: save)
                    .padding(.top, 14)
            }
            .padding(.horizontal, 16)

            Spacer(minLength: 0)
        }
        .background(Color.white)
        .presentationDetents([.height(466)])
        .presentationDragIndicator(.hidden)
        .onAppear(perform: syncInitialCollection)
    }

    private func syncInitialCollection() {
        if let card = cardStore.card(id: cardID) {
            selectedCollection = card.collection
        }
    }

    private func save() {
        cardStore.moveCard(id: cardID, to: selectedCollection)
        dismiss()
    }
}

private struct CategoryPickerChip: View {
    let kind: CollectionKind
    let isSelected: Bool

    var body: some View {
        let display = RecapPresentation.collectionDisplay(for: kind)
        Text(pickerTitle(for: kind, defaultTitle: display.title))
            .font(RecapFont.pretendard(size: 16, weight: .semibold))
            .tracking(-0.32)
            .foregroundStyle(isSelected ? display.textColor : RecapTheme.ColorToken.textTertiary)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .overlay {
                Capsule()
                    .stroke(isSelected ? display.dotColor : RecapTheme.ColorToken.border, lineWidth: 1)
            }
    }

    private func pickerTitle(for kind: CollectionKind, defaultTitle: String) -> String {
        switch kind {
        case .content:
            "책 · 컨텐츠"
        default:
            defaultTitle
        }
    }
}

#Preview("Original preview") {
    CardOriginalPreviewSheet(cardID: SampleData.cards[0].id)
        .environment(PreviewStores.recapCardStore())
}

#Preview("Share preview") {
    CardSharePreviewSheet(cardID: SampleData.cards[0].id)
        .environment(PreviewStores.recapCardStore())
}

#Preview("Collection picker") {
    CollectionPickerSheet(cardID: SampleData.cards[0].id)
        .environment(PreviewStores.recapCardStore())
}
