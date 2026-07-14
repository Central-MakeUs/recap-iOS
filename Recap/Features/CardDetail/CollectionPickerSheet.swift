import SwiftUI

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
                            CollectionPickerChip(
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

private struct CollectionPickerChip: View {
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

#Preview("정보카드 유형 선택") {
    CollectionPickerSheet(cardID: SampleData.cards[0].id)
        .environment(PreviewStores.recapCardStore())
}
