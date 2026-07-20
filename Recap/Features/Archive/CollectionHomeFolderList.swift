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
                        subtitle: display.subtitle,
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
                CollectionSummary(kind: .other, count: 0, previewTitle: "카드 없음")
            ],
            onOpenArchive: { _ in }
        )
    }
}
