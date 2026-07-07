import SwiftUI

struct HomeView: View {
    var status: HomeStatus = .ready

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: RecapTheme.Spacing.large) {
                ScreenHeader(style: .logo)

                NavigationLink(value: AppRoute.search) {
                    SearchBar(text: .constant(""))
                        .allowsHitTesting(false)
                }
                .buttonStyle(.plain)

                StatusBanner(status: status)

                SectionHeader(title: "최근 정리된 카드", actionTitle: "전체 보기")

                VStack(spacing: RecapTheme.Spacing.medium) {
                    ForEach(SampleData.recentCards.prefix(status == .complete ? 3 : 2)) { card in
                        NavigationLink(value: AppRoute.cardDetail(card.id)) {
                            InfoCardRow(card: card)
                        }
                        .buttonStyle(.plain)
                    }
                }

                SectionHeader(title: "저장 목적별 컬렉션")

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: RecapTheme.Spacing.small) {
                    ForEach(SampleData.collectionSummaries) { summary in
                        NavigationLink(value: AppRoute.collectionDetail(summary.kind)) {
                            CollectionSummaryCard(summary: summary, compact: true)
                        }
                        .buttonStyle(.plain)
                    }
                }

                ConfirmationBanner()
                    .padding(.top, RecapTheme.Spacing.small)
            }
            .padding(.horizontal, RecapTheme.Spacing.large)
            .padding(.top, RecapTheme.Spacing.large)
            .padding(.bottom, RecapTheme.Spacing.xLarge)
        }
        .background(RecapTheme.ColorToken.background)
    }
}

struct SectionHeader: View {
    let title: String
    var actionTitle: String? = nil

    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline.weight(.black))
                .foregroundStyle(RecapTheme.ColorToken.textPrimary)
            Spacer()
            if let actionTitle {
                Text(actionTitle)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(RecapTheme.ColorToken.textTertiary)
            }
        }
    }
}

#Preview("Home ready") {
    NavigationStack { HomeView(status: .ready) }
}

#Preview("Home processing") {
    NavigationStack { HomeView(status: .processing) }
}

#Preview("Home complete") {
    NavigationStack { HomeView(status: .complete) }
}

#Preview("Home waiting") {
    NavigationStack { HomeView(status: .waiting) }
}
