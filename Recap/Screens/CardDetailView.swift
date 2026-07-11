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
        case .toggleFavorite(let id):
            cardStore.toggleFavorite(id: id)
        case .exclude(let id):
            router.presentModal(.excludeCard(id))
        case .delete(let id):
            router.presentModal(.deleteCard(id))
        }
    }
}

struct CardDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isMenuPresented = false

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
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                screenshotHero

                VStack(alignment: .leading, spacing: 18) {
                    metaRow

                    VStack(alignment: .leading, spacing: 8) {
                        Text(card.title)
                            .font(RecapFont.pretendard(size: 22, weight: .semibold))
                            .tracking(-0.44)
                            .foregroundStyle(RecapTheme.ColorToken.textPrimary)

                        Text(card.summary)
                            .font(RecapFont.pretendard(size: 15, weight: .medium))
                            .tracking(-0.3)
                            .foregroundStyle(RecapTheme.ColorToken.textBody)
                    }

                    Text(card.memo)
                        .font(RecapFont.pretendard(size: 15, weight: .medium))
                        .tracking(-0.3)
                        .lineSpacing(3)
                        .foregroundStyle(RecapTheme.ColorToken.textBody)
                        .padding(.top, 21)
                }
                .padding(.horizontal, 16)
                .padding(.top, 22)
                .padding(.bottom, 40)
            }
        }
        .background(RecapTheme.ColorToken.background)
        .ignoresSafeArea(edges: .top)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $isMenuPresented) {
            CardDetailMenuSheet(
                onEdit: editCard,
                onShare: shareCard,
                onDelete: deleteCard
            )
        }
    }

    private var screenshotHero: some View {
        ZStack(alignment: .top) {
            RecapScreenshotThumbnail(kind: card.collection, assetName: card.thumbnailAssetName)
                .frame(height: 309)
                .frame(maxWidth: .infinity)
                .clipped()

            LinearGradient(
                stops: [
                    .init(color: Color.black.opacity(0.90), location: 0),
                    .init(color: Color.black.opacity(0.0), location: 1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 261)

            HStack(spacing: 12) {
                Button(action: close) {
                    RecapIconView(icon: .back, size: 24, color: .white)
                }
                .buttonStyle(.plain)

                Text("스크린샷 상세")
                    .font(RecapFont.pretendard(size: 16, weight: .semibold))
                    .tracking(-0.32)
                    .foregroundStyle(.white)

                Spacer()

                Button(action: favorite) {
                    Image(systemName: card.isFavorite ? "star.fill" : "star")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.plain)

                Button(action: menu) {
                    RecapIconView(icon: .more, size: 24, color: .white)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.top, 78)

            Button(action: openOriginal) {
                Image(systemName: "arrow.up.left.and.arrow.down.right")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 21, height: 21)
                    .background(.black.opacity(0.28))
                    .overlay {
                        RoundedRectangle(cornerRadius: 2)
                            .stroke(RecapTheme.ColorToken.border, lineWidth: 1)
                    }
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            .padding(.trailing, 21)
            .padding(.bottom, 16)
        }
        .frame(height: 309)
    }

    private var metaRow: some View {
        HStack(alignment: .center) {
            RecapCategoryPill(kind: card.collection, size: .regular)
            Spacer()
            Text(card.dateText)
                .font(RecapFont.pretendard(size: 12, weight: .medium))
                .tracking(-0.24)
                .foregroundStyle(RecapTheme.ColorToken.textTertiary)
        }
    }

    private func close() { dismiss() }
    private func openOriginal() { onAction(.openOriginal(card.id)) }
    private func favorite() { onAction(.toggleFavorite(card.id)) }
    private func menu() { isMenuPresented = true }
    private func editCard() { onAction(.edit(card.id)) }
    private func shareCard() { onAction(.share(card.id)) }
    private func deleteCard() { onAction(.delete(card.id)) }
}

private struct CardDetailMenuSheet: View {
    @Environment(\.dismiss) private var dismiss

    let onEdit: () -> Void
    let onShare: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(RecapTheme.ColorToken.border)
                .frame(width: 43, height: 5)
                .padding(.top, 13)
                .padding(.bottom, 17)

            Button {
                dismiss()
                onEdit()
            } label: {
                Text("스크린샷 정보 수정")
                    .font(RecapFont.pretendard(size: 16, weight: .semibold))
                    .tracking(-0.32)
                    .foregroundStyle(RecapTheme.ColorToken.textBody)
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(RecapTheme.ColorToken.controlFill)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .buttonStyle(.plain)

            Button {
                dismiss()
                onShare()
            } label: {
                Text("스크린샷 공유")
                    .font(RecapFont.pretendard(size: 16, weight: .semibold))
                    .tracking(-0.32)
                    .foregroundStyle(RecapTheme.ColorToken.textBody)
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(RecapTheme.ColorToken.controlFill)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .buttonStyle(.plain)
            .padding(.top, 10)

            Button {
                dismiss()
                onDelete()
            } label: {
                Text("스크린샷 삭제")
                    .font(RecapFont.pretendard(size: 16, weight: .semibold))
                    .tracking(-0.32)
                    .foregroundStyle(Color(red: 251 / 255, green: 61 / 255, blue: 61 / 255))
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(Color(red: 1, green: 239 / 255, blue: 239 / 255))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .buttonStyle(.plain)
            .padding(.top, 10)

            Button("닫기", action: { dismiss() })
                .font(RecapFont.pretendard(size: 15, weight: .medium))
                .tracking(-0.3)
                .foregroundStyle(RecapTheme.ColorToken.textBody)
                .frame(maxWidth: .infinity, minHeight: 50)
                .overlay {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(RecapTheme.ColorToken.border, lineWidth: 1)
                }
                .buttonStyle(.plain)
                .padding(.top, 24)
        }
        .padding(.horizontal, 19)
        .background(Color.white)
        .presentationDetents([.height(296)])
        .presentationDragIndicator(.hidden)
    }
}

struct MissingCardView: View {
    let cardID: InformationCard.ID

    var body: some View {
        RecapInlineEmptyView(
            title: "카드를 찾을 수 없어요",
            message: "선택한 카드가 샘플 데이터에 없습니다."
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(RecapTheme.ColorToken.background)
        .navigationTitle("카드 없음")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview("Card detail") {
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
