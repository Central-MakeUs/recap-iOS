import SwiftUI

struct CardDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(RecapCardStore.self) private var cardStore

    let card: InformationCard
    let imageState: CardDetailImageState

    @State private var isDeleteConfirmationPresented: Bool
    @State private var feedback: CardFeedback?
    @State private var isActionPanelPresented = false
    @State private var isEditing = false
    @State private var isOriginalPresented = false
    @State private var pendingPanelAction: CardDetailPanelAction?

    private var usesCategoryPill: Bool {
        isDeleteConfirmationPresented || feedback != nil
    }

    private var navigationContentColor: Color {
        imageState == .failedCard ? RecapTheme.ColorToken.textPrimary : .white
    }

    init(
        card: InformationCard,
        imageState: CardDetailImageState = .loaded,
        initiallyShowsDeleteConfirmation: Bool = false,
        initialFeedback: CardFeedback? = nil
    ) {
        self.card = card
        self.imageState = imageState
        _isDeleteConfirmationPresented = State(initialValue: initiallyShowsDeleteConfirmation)
        _feedback = State(initialValue: initialFeedback)
        _pendingPanelAction = State(initialValue: nil)
    }

    var body: some View {
        ZStack(alignment: .top) {
            detailContent
                .ignoresSafeArea(edges: .top)

            CardDetailNavigationBar(
                title: "스크린샷 상세",
                isFavorite: card.isFavorite,
                foregroundColor: navigationContentColor,
                onBack: dismiss.callAsFunction,
                onFavorite: favorite,
                onMore: showActions
            )
            .padding(.top, 20)
        }
        .background(RecapTheme.ColorToken.background)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .sheet(
            isPresented: $isActionPanelPresented,
            onDismiss: handleActionPanelDismissal
        ) {
            CardDetailActionPanel(
                onEdit: requestEdit,
                onDelete: requestDelete,
                onClose: closeActionPanel
            )
            .presentationDetents([.height(236)])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(20)
        }
        .navigationDestination(isPresented: $isEditing) {
            CardEditView(card: card)
        }
        .fullScreenCover(isPresented: $isOriginalPresented) {
            CardOriginalPreviewSheet(card: card)
        }
        .recapConfirmationDialog(
            isPresented: $isDeleteConfirmationPresented,
            title: "스크린샷을 삭제할까요?",
            message: "삭제한 스크린샷 정보는\n되돌릴 수 없어요.",
            cancelTitle: "취소",
            confirmTitle: "삭제",
            onConfirm: deleteCard
        )
        .cardFeedbackToast(feedback, horizontalPadding: 25, bottomPadding: 49)
        .task(id: feedback) {
            await clearFeedbackIfNeeded()
        }
    }

    private var detailContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                if imageState == .failedCard {
                    failedImageCard
                        .padding(.top, 145)
                    cardTextContent(topPadding: 20)
                } else {
                    screenshotHero
                    cardTextContent(topPadding: 22)
                }
            }
        }
    }

    private var screenshotHero: some View {
        ZStack(alignment: .bottomTrailing) {
            heroImage

            LinearGradient(
                stops: [
                    .init(color: Color.black.opacity(0.90), location: 0),
                    .init(color: Color.black.opacity(0), location: 1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: CardDetailStyle.heroGradientHeight)
            .frame(maxHeight: .infinity, alignment: .top)

            CardExpandButton(action: openOriginal)
                .padding(.trailing, 24)
                .padding(.bottom, 13)
        }
        .frame(height: CardDetailStyle.heroHeight)
    }

    @ViewBuilder
    private var heroImage: some View {
        switch imageState {
        case .loaded:
            RecapScreenshotThumbnail(kind: card.collection, assetName: card.detailImageAssetName)
                .frame(height: CardDetailStyle.heroHeight)
                .frame(maxWidth: .infinity)
                .clipped()
        case .failedFullWidth:
            ZStack {
                LinearGradient(
                    colors: [CardDetailStyle.imageFailureFill, .white],
                    startPoint: .top,
                    endPoint: .bottom
                )
                CardImageFailureView()
            }
            .frame(height: CardDetailStyle.heroHeight)
        case .failedCard:
            EmptyView()
        }
    }

    private var failedImageCard: some View {
        ZStack(alignment: .bottomTrailing) {
            CardDetailStyle.imageFailureFill
            CardImageFailureView()
            CardExpandButton(
                foregroundColor: RecapTheme.ColorToken.textTertiary,
                backgroundColor: .white,
                action: openOriginal
            )
            .padding(.trailing, 8)
            .padding(.bottom, 8)
        }
        .frame(height: CardDetailStyle.imageCardHeight)
        .clipShape(RoundedRectangle(cornerRadius: CardDetailStyle.cornerRadius, style: .continuous))
        .padding(.horizontal, CardDetailStyle.horizontalPadding)
    }

    private func cardTextContent(topPadding: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            metaRow

            Text(card.title)
                .font(RecapFont.pretendard(size: 22, weight: .semibold))
                .tracking(-0.44)
                .foregroundStyle(RecapTheme.ColorToken.textPrimary)
                .padding(.top, 24)

            Text(card.summary)
                .font(RecapFont.pretendard(size: 15, weight: .medium))
                .tracking(-0.3)
                .foregroundStyle(RecapTheme.ColorToken.textBody)
                .padding(.top, 8)

            Text(detailBody)
                .font(RecapFont.pretendard(size: 15, weight: .medium))
                .tracking(-0.3)
                .lineSpacing(3)
                .foregroundStyle(RecapTheme.ColorToken.textBody)
                .padding(.top, 40)
        }
        .padding(.horizontal, CardDetailStyle.horizontalPadding)
        .padding(.top, topPadding)
        .padding(.bottom, 40)
    }

    private var metaRow: some View {
        HStack {
            if !usesCategoryPill {
                Text(RecapPresentation.collectionDisplay(for: card.collection).title)
                    .font(RecapFont.pretendard(size: 14, weight: .semibold))
                    .tracking(-0.28)
                    .foregroundStyle(RecapPresentation.collectionDisplay(for: card.collection).textColor)
            } else {
                RecapCategoryPill(kind: card.collection, size: .regular)
            }

            Spacer()

            Text(card.dateText)
                .font(RecapFont.pretendard(size: 12, weight: .medium))
                .tracking(-0.24)
                .foregroundStyle(RecapTheme.ColorToken.textTertiary)
        }
    }

    private var detailBody: String {
        card.memo
    }

    private func openOriginal() { isOriginalPresented = true }
    private func showActions() { isActionPanelPresented = true }

    private func favorite() {
        feedback = CardFeedback(
            kind: .success,
            message: card.isFavorite
                ? "즐겨찾기에서 삭제했어요."
                : "즐겨찾기에 추가했어요."
        )
        cardStore.toggleFavorite(id: card.id)
    }

    private func requestEdit() {
        pendingPanelAction = .edit
        isActionPanelPresented = false
    }

    private func requestDelete() {
        pendingPanelAction = .delete
        isActionPanelPresented = false
    }

    private func closeActionPanel() {
        pendingPanelAction = nil
        isActionPanelPresented = false
    }

    private func handleActionPanelDismissal() {
        defer { pendingPanelAction = nil }

        switch pendingPanelAction {
        case .edit:
            isEditing = true
        case .delete:
            isDeleteConfirmationPresented = true
        case nil:
            break
        }
    }

    private func deleteCard() {
        cardStore.removeCard(id: card.id)
        dismiss()
    }

    private func clearFeedbackIfNeeded() async {
        guard feedback != nil else { return }
        try? await Task.sleep(for: .seconds(2))
        guard !Task.isCancelled else { return }
        feedback = nil
    }
}

private enum CardDetailPanelAction {
    case edit
    case delete
}

#Preview("정보카드 상세") {
    NavigationStack {
        CardDetailView(card: SampleData.cards[1])
    }
    .environment(AppRouter())
    .environment(PreviewStores.recapCardStore())
}
