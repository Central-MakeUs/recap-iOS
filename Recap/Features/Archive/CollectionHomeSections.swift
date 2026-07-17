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
        .padding(.horizontal, -16)
    }
}

struct CollectionHomeEmptyState: View {
    let onImportScreenshots: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            RecapSearchEmptyIllustration(size: 123)

            Text("아직 정리된 스크린샷이 없어요")
                .font(RecapFont.pretendard(size: 16, weight: .semibold))
                .tracking(-0.32)
                .foregroundStyle(Color.recapGray300)
                .padding(.top, 20)

            Text("정리할 스크린샷을 불러오거나\n갤러리에서 공유해주세요")
                .font(RecapFont.pretendard(size: 14, weight: .regular))
                .tracking(-0.28)
                .lineSpacing(1)
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.recapGray300)
                .padding(.top, 9)

            Button("스크린샷 불러오기", action: onImportScreenshots)
                .font(RecapFont.pretendard(size: 14, weight: .semibold))
                .tracking(-0.28)
                .foregroundStyle(Color.recapBlue300)
                .frame(width: 155, height: 45)
                .background(Color.recapBlue50)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .buttonStyle(.plain)
                .padding(.top, 23)
        }
    }
}

#Preview("보관함 폴더 격자") {
    CollectionHomeFolderGrid(
        summaries: SampleData.collectionSummaries + [
            CollectionSummary(kind: .other, count: 0, previewTitle: "카드 없음")
        ],
        onOpenArchive: { _ in }
    )
    .padding()
}

#Preview("보관함 빈 상태") {
    CollectionHomeEmptyState(onImportScreenshots: {})
}
