import SwiftUI

struct ArchiveHomeFolderList: View {
    let summaries: [CategorySummary]
    let onOpenArchive: (CardCategory) -> Void

    var body: some View {
        VStack(spacing: 0) {
            ForEach(summaries) { summary in
                Button {
                    onOpenArchive(summary.category)
                } label: {
                    let display = RecapPresentation.categoryDisplay(for: summary.category)
                    RecapFolderListRow(
                        title: display.title,
                        subtitle: summary.previewTitle,
                        count: summary.count,
                        category: summary.category
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

#if DEBUG
#Preview("보관함 폴더 목록") {
    ScrollView {
        ArchiveHomeFolderList(
            summaries: SampleData.categorySummaries + [
                CategorySummary(category: .other, count: 0, previewTitle: "")
            ],
            onOpenArchive: { _ in }
        )
    }
}
#endif
