import SwiftUI

struct SearchTargetCardEmptyState: View {
    var body: some View {
        VStack(spacing: 18) {
            Spacer()

            RecapIncompleteCallout(
                title: "대상 카드 없음",
                message: "표시할 카드가 없습니다. 데이터를 불러온 뒤 다시 확인해주세요."
            )
            .padding(.horizontal, 28)

            Spacer()
        }
    }
}

#Preview("검색 대상 카드 없음") {
    SearchTargetCardEmptyState()
        .background(Color.recapBackground)
}
