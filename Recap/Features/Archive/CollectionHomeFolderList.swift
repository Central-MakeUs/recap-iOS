import SwiftUI

struct CollectionHomeFolderList: View {
    let summaries: [CollectionSummary]
    let onOpenArchive: (CollectionKind) -> Void

    var body: some View {
        VStack(spacing: 0) {
            ForEach(summaries) { summary in
                Button {
                    onOpenArchive(summary.kind)
                } label: {
                    let display = RecapPresentation.collectionDisplay(for: summary.kind)
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

#Preview("보관함 폴더 목록") {
    ScrollView {
        CollectionHomeFolderList(
            summaries: SampleData.collectionSummaries + [
                CollectionSummary(kind: .other, count: 0, previewTitle: "")
            ],
            onOpenArchive: { _ in }
        )
    }
}
