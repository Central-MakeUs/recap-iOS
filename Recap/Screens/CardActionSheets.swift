import SwiftUI

struct CardOriginalPreviewSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(RecapCardStore.self) private var cardStore

    let cardID: InformationCard.ID

    private var card: InformationCard? {
        cardStore.card(id: cardID)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: RecapTheme.Spacing.large) {
                RoundedRectangle(cornerRadius: RecapTheme.Radius.large, style: .continuous)
                    .fill(RecapTheme.ColorToken.thumbnail)
                    .overlay {
                        Text(card?.title ?? "원본 이미지")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(RecapTheme.ColorToken.textSecondary)
                    }
                    .frame(height: 260)

                Text("원본 이미지는 아직 실제 저장소에 연결하지 않았습니다. 이 화면은 원본 보기 액션이 조용히 실패하지 않도록 둔 자리표시자입니다.")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(RecapTheme.ColorToken.textSecondary)
                    .padding(.horizontal, RecapTheme.Spacing.large)
            }
            .padding(RecapTheme.Spacing.large)
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

    private func close() {
        dismiss()
    }
}

struct CardSharePreviewSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(RecapCardStore.self) private var cardStore

    let cardID: InformationCard.ID

    private var card: InformationCard? {
        cardStore.card(id: cardID)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: RecapTheme.Spacing.large) {
                Image(systemName: "square.and.arrow.up")
                    .font(.title.weight(.bold))
                    .foregroundStyle(RecapTheme.ColorToken.primary)
                    .frame(width: 64, height: 64)
                    .background(RecapTheme.ColorToken.primaryLight)
                    .clipShape(RoundedRectangle(cornerRadius: RecapTheme.Radius.large, style: .continuous))

                VStack(spacing: RecapTheme.Spacing.small) {
                    Text(card?.title ?? "카드 공유")
                        .font(.title3.weight(.black))
                        .foregroundStyle(RecapTheme.ColorToken.textPrimary)
                    Text("공유 시트 연결은 다음 단계의 실제 기능으로 남기고, 지금은 공유 액션 진입만 명확히 확인합니다.")
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(RecapTheme.ColorToken.textSecondary)
                }
            }
            .padding(RecapTheme.Spacing.xLarge)
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
}

struct CollectionPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(RecapCardStore.self) private var cardStore

    let cardID: InformationCard.ID
    @State private var selectedCollection: CollectionKind

    init(cardID: InformationCard.ID, initialCollection: CollectionKind = .comparison) {
        self.cardID = cardID
        _selectedCollection = State(initialValue: initialCollection)
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(CollectionKind.allCases) { kind in
                    Button {
                        select(kind)
                    } label: {
                        HStack {
                            let display = RecapPresentation.collectionDisplay(for: kind)
                            Circle()
                                .fill(display.dotColor)
                                .frame(width: 9, height: 9)
                            Text(display.title)
                                .foregroundStyle(RecapTheme.ColorToken.textPrimary)
                            Spacer()
                            if selectedCollection == kind {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(RecapTheme.ColorToken.primary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("컬렉션 변경")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소", action: close)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("완료", action: save)
                }
            }
        }
        .onAppear(perform: syncInitialCollection)
    }

    private func syncInitialCollection() {
        if let card = cardStore.card(id: cardID) {
            selectedCollection = card.collection
        }
    }

    private func select(_ kind: CollectionKind) {
        selectedCollection = kind
    }

    private func save() {
        cardStore.moveCard(id: cardID, to: selectedCollection)
        dismiss()
    }

    private func close() {
        dismiss()
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
