import SwiftUI

struct MissingCardView: View {
    let cardID: InformationCard.ID

    var body: some View {
        RecapInlineEmptyView(
            title: "카드를 찾을 수 없어요",
            message: "선택한 카드가 샘플 데이터에 없습니다."
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(RecapTheme.ColorToken.background)
        .navigationTitle("카드 없음")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview("정보카드 없음") {
    NavigationStack {
        MissingCardView(cardID: UUID())
    }
}
