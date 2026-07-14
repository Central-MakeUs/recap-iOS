import SwiftUI

struct CardDetailView: View {
    @Environment(\.dismiss) private var dismiss

    let card: InformationCard
    let imageState: CardDetailImageState
    let onAction: (CardDetailAction) -> Void

    @State private var overlayState: CardDetailOverlayState
    @State private var favoriteToastMessage: String

    init(
        card: InformationCard,
        imageState: CardDetailImageState = .loaded,
        initialOverlay: CardDetailOverlayState = .none,
        onAction: @escaping (CardDetailAction) -> Void
    ) {
        self.card = card
        self.imageState = imageState
        self.onAction = onAction
        _overlayState = State(initialValue: initialOverlay)
        _favoriteToastMessage = State(initialValue: "즐겨찾기에 추가했어요.")
    }

    var body: some View {
        ZStack {
            detailContent

            overlay
        }
        .background(RecapTheme.ColorToken.background)
        .ignoresSafeArea(edges: .top)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .task(id: overlayState) {
            await clearTransientOverlayIfNeeded()
        }
    }

    private var detailContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                if imageState == .failedCard {
                    compactHeader
                    failedImageCard
                    cardTextContent(topPadding: 20)
                } else {
                    screenshotHero
                    cardTextContent(topPadding: 22)
                }
            }
        }
    }

    private var screenshotHero: some View {
        ZStack(alignment: .topTrailing) {
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

            detailHeader(color: .white)
                .padding(.top, 78)

            CardExpandButton(action: openOriginal)
                .padding(.top, 248)
                .padding(.trailing, 24)
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

    private var compactHeader: some View {
        detailHeader(color: RecapTheme.ColorToken.textPrimary)
            .padding(.top, 78)
            .padding(.bottom, 43)
    }

    private func detailHeader(color: Color) -> some View {
        HStack(spacing: 13) {
            Button(action: close) {
                RecapIconView(icon: .back, size: 24, color: color)
            }
            .buttonStyle(.plain)

            Text("스크린샷 상세")
                .font(RecapFont.pretendard(size: 16, weight: .semibold))
                .tracking(-0.32)
                .foregroundStyle(color)

            Spacer()

            Button(action: favorite) {
                Image(systemName: card.isFavorite ? "star.fill" : "star.fill")
                    .font(.system(size: 20, weight: .regular))
                    .foregroundStyle(card.isFavorite ? RecapTheme.ColorToken.primary : color.opacity(0.70))
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.plain)

            RecapIconView(icon: .more, size: 24, color: color)
                .contentShape(Rectangle())
                .onTapGesture(perform: showActions)
                .accessibilityAddTraits(.isButton)
        }
        .padding(.horizontal, CardDetailStyle.horizontalPadding)
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
            if overlayState == .none {
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

    @ViewBuilder
    private var overlay: some View {
        switch overlayState {
        case .none:
            EmptyView()
        case .actions:
            ZStack(alignment: .bottom) {
                CardDetailStyle.dim
                    .ignoresSafeArea()
                CardDetailActionPanel(
                    onEdit: editCard,
                    onDelete: { overlayState = .deleteConfirmation },
                    onClose: { overlayState = .none }
                )
            }
            .ignoresSafeArea(edges: .bottom)
        case .deleteConfirmation:
            ZStack {
                CardDetailStyle.dim.ignoresSafeArea()
                CardConfirmationDialog(
                    title: "스크린샷을 삭제할까요?",
                    message: "삭제한 스크린샷 정보는\n되돌릴 수 없어요.",
                    cancelTitle: "취소",
                    confirmTitle: "삭제",
                    onCancel: { overlayState = .none },
                    onConfirm: deleteCard
                )
            }
        case .favoriteToast:
            CardFeedbackToast(
                kind: .success,
                message: favoriteToastMessage
            )
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                .padding(.bottom, 49)
        case .deleteFailure:
            CardFeedbackToast(kind: .failure, message: "스크린샷을 삭제하지 못했어요. 다시 시도해주세요.")
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                .padding(.horizontal, 25)
                .padding(.bottom, 49)
        }
    }

    private var detailBody: String {
        card.memo
    }

    private func close() { dismiss() }
    private func openOriginal() { onAction(.openOriginal(card.id)) }
    private func showActions() { overlayState = .actions }

    private func favorite() {
        favoriteToastMessage = card.isFavorite
            ? "즐겨찾기에서 삭제했어요."
            : "즐겨찾기에 추가했어요."
        onAction(.toggleFavorite(card.id))
        overlayState = .favoriteToast
    }

    private func editCard() {
        overlayState = .none
        onAction(.edit(card.id))
    }

    private func deleteCard() {
        overlayState = .none
        onAction(.delete(card.id))
    }

    private func clearTransientOverlayIfNeeded() async {
        guard overlayState == .favoriteToast || overlayState == .deleteFailure else { return }
        try? await Task.sleep(for: .seconds(2))
        guard !Task.isCancelled else { return }
        overlayState = .none
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
