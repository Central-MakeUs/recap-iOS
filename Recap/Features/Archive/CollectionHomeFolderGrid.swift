import SwiftUI

struct CollectionHomeFolderGrid: View {
    let summaries: [CollectionSummary]
    let onOpenArchive: (CardCategory) -> Void

    private let columns = [
        GridItem(.flexible(minimum: 99), spacing: 0, alignment: .leading),
        GridItem(.flexible(minimum: 99), spacing: 0, alignment: .center),
        GridItem(.flexible(minimum: 99), spacing: 0, alignment: .trailing)
    ]

    var body: some View {
        LazyVGrid(
            columns: columns,
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
        .frame(maxWidth: .infinity)
    }
}

#if DEBUG
#Preview("보관함 폴더 격자") {
    CollectionHomeFolderGrid(
        summaries: SampleData.collectionSummaries + [
            CollectionSummary(kind: .other, count: 0, previewTitle: "")
        ],
        onOpenArchive: { _ in }
    )
    .padding()
}
#endif
