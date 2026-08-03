import SwiftUI

struct CollectionHomeFolderGrid: View {
    let summaries: [CollectionSummary]
    let onOpenArchive: (CollectionKind) -> Void

    var body: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.fixed(99), spacing: 23), count: 3),
            alignment: .leading,
            spacing: 15
        ) {
            ForEach(summaries) { summary in
                Button {
                    onOpenArchive(summary.kind)
                } label: {
                    let display = RecapPresentation.collectionDisplay(for: summary.kind)
                    RecapFolderCard(
                        title: display.title,
                        count: summary.count,
                        kind: summary.kind
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .frame(width: 343, alignment: .leading)
    }
}

#Preview("보관함 폴더 격자") {
    CollectionHomeFolderGrid(
        summaries: SampleData.collectionSummaries + [
            CollectionSummary(kind: .other, count: 0, previewTitle: "")
        ],
        onOpenArchive: { _ in }
    )
    .padding()
}
