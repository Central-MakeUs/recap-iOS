import SwiftUI

struct CardDetailContainerView: View {
    @Environment(AppRouter.self) private var router
    @Environment(RecapCardStore.self) private var cardStore

    let cardID: InformationCard.ID

    var body: some View {
        if let card = cardStore.card(id: cardID) {
            CardDetailView(card: card, onAction: handleAction)
        } else {
            MissingCardView(cardID: cardID)
        }
    }

    private func handleAction(_ action: CardDetailAction) {
        switch action {
        case .openOriginal(let id):
            router.presentSheet(.originalPreview(cardID: id))
        case .share(let id):
            router.presentSheet(.sharePreview(cardID: id))
        case .edit(let id):
            router.navigate(.cardEdit(id))
        case .changeCollection(let id):
            router.presentSheet(.collectionPicker(cardID: id))
        case .exclude(let id):
            router.presentModal(.excludeCard(id))
        case .delete(let id):
            router.presentModal(.deleteCard(id))
        }
    }
}

struct CardDetailView: View {
    let card: InformationCard
    let onAction: (CardDetailAction) -> Void

    init(
        card: InformationCard,
        onAction: @escaping (CardDetailAction) -> Void
    ) {
        self.card = card
        self.onAction = onAction
    }

    var body: some View {
        let collection = RecapPresentation.collectionDisplay(for: card.collection)

        ScrollView {
            VStack(alignment: .leading, spacing: RecapTheme.Spacing.large) {
                screenshotPreview

                detailTable

                HStack(spacing: RecapTheme.Spacing.small) {
                    Text(collection.title)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(collection.dotColor)
                        .padding(.horizontal, RecapTheme.Spacing.medium)
                        .padding(.vertical, RecapTheme.Spacing.small)
                        .background(collection.dotColor.opacity(0.10))
                        .clipShape(RoundedRectangle(cornerRadius: RecapTheme.Radius.small, style: .continuous))
                    Text(card.dateText + " 저장")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(RecapTheme.ColorToken.textTertiary)
                }

                memoBox

                HStack(spacing: RecapTheme.Spacing.small) {
                    ForEach(card.tags, id: \.self) { tag in
                        Text("#\(tag)")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(RecapTheme.ColorToken.primary)
                            .padding(.horizontal, RecapTheme.Spacing.medium)
                            .padding(.vertical, RecapTheme.Spacing.small)
                            .background(RecapTheme.ColorToken.primary.opacity(0.10))
                            .clipShape(RoundedRectangle(cornerRadius: RecapTheme.Radius.small, style: .continuous))
                    }
                }
            }
            .padding(RecapTheme.Spacing.large)
            .padding(.bottom, 110)
        }
        .background(RecapTheme.ColorToken.background)
        .navigationTitle(card.title)
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            bottomActions
        }
    }

    private var screenshotPreview: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: RecapTheme.Radius.large, style: .continuous)
                .fill(RecapTheme.ColorToken.thumbnail)
                .overlay(
                    diagonalPattern
                        .clipShape(RoundedRectangle(cornerRadius: RecapTheme.Radius.large, style: .continuous))
                )
                .frame(height: 160)

            Text("원본 스크린샷")
                .font(.caption.weight(.semibold))
                .foregroundStyle(RecapTheme.ColorToken.textSecondary)
                .padding(.horizontal, RecapTheme.Spacing.medium)
                .padding(.vertical, RecapTheme.Spacing.small)
                .background(.white.opacity(0.75))
                .clipShape(Capsule())
                .padding(RecapTheme.Spacing.medium)

            Button(action: openOriginal) {
                Label("원본 보기", systemImage: "rectangle")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, RecapTheme.Spacing.medium)
                    .padding(.vertical, RecapTheme.Spacing.small)
                    .background(RecapTheme.ColorToken.textPrimary.opacity(0.82))
                    .clipShape(RoundedRectangle(cornerRadius: RecapTheme.Radius.small, style: .continuous))
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            .padding(RecapTheme.Spacing.medium)
        }
    }

    private var diagonalPattern: some View {
        Canvas { context, size in
            let lineColor = Color.white.opacity(0.18)
            for offset in stride(from: -size.height, through: size.width, by: 18) {
                var path = Path()
                path.move(to: CGPoint(x: offset, y: size.height))
                path.addLine(to: CGPoint(x: offset + size.height, y: 0))
                context.stroke(path, with: .color(lineColor), lineWidth: 1)
            }
        }
    }

    private var detailTable: some View {
        VStack(spacing: 0) {
            DetailRow(title: "위치", value: card.location)
            Divider().background(RecapTheme.ColorToken.divider)
            DetailRow(title: "영업시간", value: card.businessHours)
            Divider().background(RecapTheme.ColorToken.divider)
            DetailRow(title: "유형", value: card.category)
            if let confirmationLabel = card.confirmationLabel {
                Divider().background(RecapTheme.ColorToken.divider)
                DetailRow(title: "확인 필요", value: confirmationLabel, highlighted: true)
            }
        }
        .recapCard()
    }

    private var memoBox: some View {
        HStack(alignment: .top, spacing: RecapTheme.Spacing.medium) {
            Image(systemName: "note.text")
                .foregroundStyle(RecapTheme.ColorToken.warning)
            VStack(alignment: .leading, spacing: 4) {
                Text("메모")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(RecapTheme.ColorToken.textPrimary)
                Text(card.memo)
                    .font(.subheadline)
                    .foregroundStyle(RecapTheme.ColorToken.textPrimary)
            }
        }
        .padding(RecapTheme.Spacing.medium)
        .recapCard(borderColor: Color(red: 0.970, green: 0.870, blue: 0.610), fill: RecapTheme.ColorToken.warningSoft)
    }

    private var bottomActions: some View {
        VStack(spacing: RecapTheme.Spacing.small) {
            HStack(spacing: RecapTheme.Spacing.small) {
                RecapButton(title: "공유", style: .secondary, action: shareCard)
                RecapButton(title: "카드 수정", style: .secondary, action: editCard)
                RecapButton(title: "컬렉션 변경", style: .primary, action: changeCollection)
            }

            HStack(spacing: RecapTheme.Spacing.large) {
                Button("RE-CAP에서 제외", action: excludeCard)
                    .buttonStyle(.plain)
                Text("|")
                    .foregroundStyle(RecapTheme.ColorToken.textTertiary)
                Button("카드 삭제", action: deleteCard)
                    .foregroundStyle(.red)
                    .buttonStyle(.plain)
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(RecapTheme.ColorToken.textTertiary)
        }
        .padding(.horizontal, RecapTheme.Spacing.large)
        .padding(.top, RecapTheme.Spacing.medium)
        .padding(.bottom, RecapTheme.Spacing.small)
        .background(.ultraThinMaterial)
    }

    private func openOriginal() {
        onAction(.openOriginal(card.id))
    }

    private func shareCard() {
        onAction(.share(card.id))
    }

    private func editCard() {
        onAction(.edit(card.id))
    }

    private func changeCollection() {
        onAction(.changeCollection(card.id))
    }

    private func excludeCard() {
        onAction(.exclude(card.id))
    }

    private func deleteCard() {
        onAction(.delete(card.id))
    }
}

struct MissingCardView: View {
    let cardID: InformationCard.ID

    var body: some View {
        VStack(spacing: RecapTheme.Spacing.large) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.title.weight(.bold))
                .foregroundStyle(RecapTheme.ColorToken.textTertiary)
                .frame(width: 64, height: 64)
                .background(RecapTheme.ColorToken.surface)
                .clipShape(RoundedRectangle(cornerRadius: RecapTheme.Radius.large, style: .continuous))

            VStack(spacing: RecapTheme.Spacing.small) {
                Text("카드를 찾을 수 없어요")
                    .font(.title3.weight(.black))
                    .foregroundStyle(RecapTheme.ColorToken.textPrimary)

                Text("선택한 카드가 샘플 데이터에 없어서 잘못된 상세 화면을 대신 보여주지 않았습니다.")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(RecapTheme.ColorToken.textSecondary)
            }

            Text(cardID.uuidString)
                .font(.caption2.monospaced())
                .foregroundStyle(RecapTheme.ColorToken.textTertiary)
                .lineLimit(1)
                .truncationMode(.middle)
                .padding(.horizontal, RecapTheme.Spacing.medium)
        }
        .padding(RecapTheme.Spacing.xLarge)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(RecapTheme.ColorToken.background)
        .navigationTitle("카드 없음")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct DetailRow: View {
    let title: String
    let value: String
    var highlighted = false

    var body: some View {
        HStack {
            Text(title)
                .font(.caption)
                .foregroundStyle(RecapTheme.ColorToken.textSecondary)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(highlighted ? RecapTheme.ColorToken.warning : RecapTheme.ColorToken.textPrimary)
                .padding(.horizontal, highlighted ? RecapTheme.Spacing.small : 0)
                .padding(.vertical, highlighted ? 4 : 0)
                .background(highlighted ? RecapTheme.ColorToken.warningSoft : .clear)
                .clipShape(Capsule())
        }
        .padding(RecapTheme.Spacing.medium)
    }
}

#Preview {
    NavigationStack {
        CardDetailView(
            card: SampleData.cards[0],
            onAction: PreviewActions.handleCardDetail
        )
    }
}

#Preview("Missing card") {
    NavigationStack { MissingCardView(cardID: UUID()) }
}
