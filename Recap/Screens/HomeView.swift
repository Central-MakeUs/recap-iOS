import SwiftUI

struct HomeContainerView: View {
    @Environment(AppRouter.self) private var router
    @Environment(RecapCardStore.self) private var cardStore

    var body: some View {
        HomeView(
            status: .ready,
            recentCards: cardStore.recentCards,
            collectionSummaries: cardStore.collectionSummaries,
            onAction: handleAction
        )
    }

    private func handleAction(_ action: HomeAction) {
        switch action {
        case .search:
            router.navigate(.search)
        case .openAllRecent:
            router.navigate(.allRecentCards)
        case .openCard(let id):
            router.navigate(.cardDetail(id))
        case .openArchive(let kind):
            router.navigate(.archiveDetail(kind))
        case .openSettings:
            router.navigate(.settings)
        }
    }
}

struct HomeView: View {
    var status: HomeStatus = .ready
    let recentCards: [InformationCard]
    let collectionSummaries: [CollectionSummary]
    let onAction: (HomeAction) -> Void

    init(
        status: HomeStatus = .ready,
        recentCards: [InformationCard],
        collectionSummaries: [CollectionSummary],
        onAction: @escaping (HomeAction) -> Void
    ) {
        self.status = status
        self.recentCards = recentCards
        self.collectionSummaries = collectionSummaries
        self.onAction = onAction
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: RecapTheme.Spacing.large) {
                HStack(spacing: RecapTheme.Spacing.medium) {
                    HStack(spacing: RecapTheme.Spacing.small) {
                        Text("R")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white)
                            .frame(width: 28, height: 28)
                            .background(RecapTheme.ColorToken.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                        Text("RE-CAP")
                            .font(.headline.weight(.black))
                            .foregroundStyle(RecapTheme.ColorToken.textPrimary)
                    }

                    Spacer()

                    Button(action: openSettings) {
                        Image(systemName: "ellipsis")
                            .rotationEffect(.degrees(90))
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(RecapTheme.ColorToken.textSecondary)
                            .frame(width: 32, height: 32)
                            .background(RecapTheme.ColorToken.surface)
                            .clipShape(RoundedRectangle(cornerRadius: RecapTheme.Radius.small, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: RecapTheme.Radius.small, style: .continuous)
                                    .stroke(RecapTheme.ColorToken.border, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("설정 열기")
                }

                Button(action: openSearch) {
                    SearchBar(text: .constant(""), placeholder: "카드 제목 또는 핵심 정보 검색")
                        .allowsHitTesting(false)
                }
                .buttonStyle(.plain)

                let statusDisplay = RecapPresentation.statusDisplay(for: status)
                HStack(alignment: .top, spacing: RecapTheme.Spacing.medium) {
                    Image(systemName: statusDisplay.iconName)
                        .font(.footnote.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(width: 28, height: 28)
                        .background(statusDisplay.tint)
                        .clipShape(Circle())

                    VStack(alignment: .leading, spacing: RecapTheme.Spacing.small) {
                        Text(statusDisplay.title)
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(RecapTheme.ColorToken.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)

                        Text(statusDisplay.message)
                            .font(.caption)
                            .foregroundStyle(RecapTheme.ColorToken.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)

                        if let progress = statusDisplay.progress {
                            VStack(alignment: .leading, spacing: RecapTheme.Spacing.xSmall) {
                                HStack {
                                    Text("진행 상태")
                                    Spacer()
                                    Text("2 / 3개 완료")
                                }
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(RecapTheme.ColorToken.primary)

                                ProgressView(value: progress)
                                    .tint(RecapTheme.ColorToken.primary)
                            }
                        }
                    }
                }
                .padding(RecapTheme.Spacing.large)
                .recapCard(fill: statusDisplay.background)

                SectionHeader(
                    title: "최근 정리된 카드",
                    actionTitle: "전체 보기",
                    onAction: openAllRecent
                )

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: RecapTheme.Spacing.medium) {
                        ForEach(visibleRecentCards) { card in
                            Button {
                                openCard(card.id)
                            } label: {
                                RecentRecapCard(card: card)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                SectionHeader(title: "저장 목적별 컬렉션")

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: RecapTheme.Spacing.small) {
                    ForEach(collectionSummaries) { summary in
                        Button {
                            openArchive(summary.kind)
                        } label: {
                            let collection = RecapPresentation.collectionDisplay(for: summary.kind)
                            HStack(spacing: RecapTheme.Spacing.medium) {
                                RoundedRectangle(cornerRadius: RecapTheme.Radius.small, style: .continuous)
                                    .fill(collection.dotColor.opacity(0.14))
                                    .frame(width: 16, height: 16)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                                            .fill(collection.dotColor)
                                            .frame(width: 8, height: 8)
                                    )

                                VStack(alignment: .leading, spacing: 3) {
                                    Text(collection.title)
                                        .font(.subheadline.weight(.bold))
                                        .foregroundStyle(RecapTheme.ColorToken.textPrimary)
                                    Text("\(summary.count)")
                                        .font(.caption)
                                        .foregroundStyle(RecapTheme.ColorToken.textSecondary)
                                        .lineLimit(1)
                                }

                                Spacer()
                            }
                            .padding(RecapTheme.Spacing.small)
                            .recapCard(radius: RecapTheme.Radius.medium)
                        }
                        .buttonStyle(.plain)
                    }
                }

                HStack(spacing: RecapTheme.Spacing.medium) {
                    Image(systemName: "exclamationmark")
                        .font(.caption.weight(.black))
                        .foregroundStyle(RecapTheme.ColorToken.warning)
                        .frame(width: 24, height: 24)
                        .background(RecapTheme.ColorToken.warningSoft)
                        .clipShape(RoundedRectangle(cornerRadius: RecapTheme.Radius.small, style: .continuous))

                    VStack(alignment: .leading, spacing: 2) {
                        Text("확인이 필요한 카드 1개")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(RecapTheme.ColorToken.textPrimary)
                        Text("분류가 애매한 카드는 따로 확인할 수 있어요")
                            .font(.caption)
                            .foregroundStyle(RecapTheme.ColorToken.textSecondary)
                    }

                    Spacer()

                    Image(systemName: "arrow.right")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(RecapTheme.ColorToken.warning)
                }
                .padding(RecapTheme.Spacing.medium)
                .recapCard(borderColor: Color(red: 0.970, green: 0.830, blue: 0.560), fill: RecapTheme.ColorToken.warningSoft)
                    .padding(.top, RecapTheme.Spacing.small)
            }
            .padding(.horizontal, RecapTheme.Spacing.large)
            .padding(.top, RecapTheme.Spacing.large)
            .padding(.bottom, RecapTheme.Spacing.xLarge)
        }
        .background(RecapTheme.ColorToken.background)
    }

    private var visibleRecentCards: [InformationCard] {
        Array(recentCards.prefix(status == .complete ? 3 : 2))
    }

    private func openSearch() {
        onAction(.search)
    }

    private func openAllRecent() {
        onAction(.openAllRecent)
    }

    private func openCard(_ id: InformationCard.ID) {
        onAction(.openCard(id))
    }

    private func openArchive(_ kind: CollectionKind) {
        onAction(.openArchive(kind))
    }

    private func openSettings() {
        onAction(.openSettings)
    }
}

struct SectionHeader: View {
    let title: String
    var actionTitle: String? = nil
    var onAction: (() -> Void)? = nil

    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline.weight(.black))
                .foregroundStyle(RecapTheme.ColorToken.textPrimary)
            Spacer()
            if let actionTitle {
                if let onAction {
                    Button(actionTitle, action: onAction)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(RecapTheme.ColorToken.textTertiary)
                        .buttonStyle(.plain)
                } else {
                    Text(actionTitle)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(RecapTheme.ColorToken.textTertiary)
                }
            }
        }
    }
}

#Preview("Home ready") {
    NavigationStack {
        HomeView(
            status: .ready,
            recentCards: SampleData.recentCards,
            collectionSummaries: SampleData.collectionSummaries,
            onAction: PreviewActions.handleHome
        )
    }
}

#Preview("Home processing") {
    NavigationStack {
        HomeView(
            status: .processing,
            recentCards: SampleData.recentCards,
            collectionSummaries: SampleData.collectionSummaries,
            onAction: PreviewActions.handleHome
        )
    }
}

#Preview("Home complete") {
    NavigationStack {
        HomeView(
            status: .complete,
            recentCards: SampleData.recentCards,
            collectionSummaries: SampleData.collectionSummaries,
            onAction: PreviewActions.handleHome
        )
    }
}

#Preview("Home waiting") {
    NavigationStack {
        HomeView(
            status: .waiting,
            recentCards: SampleData.recentCards,
            collectionSummaries: SampleData.collectionSummaries,
            onAction: PreviewActions.handleHome
        )
    }
}
