import SwiftUI

struct ArchiveHomeFolderList: View {
    let summaries: [CategorySummary]
    let onOpenArchive: (CardCategory) -> Void

    var body: some View {
        VStack(spacing: 0) {
            ForEach(summaries) { summary in
                Button {
                    onOpenArchive(summary.kind)
                } label: {
                    let display = RecapPresentation.categoryDisplay(for: summary.kind)
                    RecapFolderListRow(
                        title: display.title,
                        subtitle: summary.previewTitle,
                        count: summary.count,
                        kind: summary.kind
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
                CategorySummary(kind: .other, count: 0, previewTitle: "")
            ],
            onOpenArchive: { _ in }
        )
    }
}
#endif
