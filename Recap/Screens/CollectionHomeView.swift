import SwiftUI

struct CollectionHomeView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: RecapTheme.Spacing.large) {
                ScreenHeader(style: .title("컬렉션"))

                NavigationLink(value: AppRoute.search) {
                    SearchBar(text: .constant(""))
                        .allowsHitTesting(false)
                }
                .buttonStyle(.plain)

                SectionHeader(title: "기본 컬렉션")

                VStack(spacing: RecapTheme.Spacing.medium) {
                    ForEach(SampleData.collectionSummaries) { summary in
                        NavigationLink(value: AppRoute.collectionDetail(summary.kind)) {
                            CollectionSummaryCard(summary: summary)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, RecapTheme.Spacing.large)
            .padding(.top, RecapTheme.Spacing.large)
            .padding(.bottom, RecapTheme.Spacing.xLarge)
        }
        .background(RecapTheme.ColorToken.background)
    }
}

#Preview {
    NavigationStack { CollectionHomeView() }
}
