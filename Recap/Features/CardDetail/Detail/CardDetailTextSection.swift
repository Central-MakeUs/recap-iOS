import SwiftUI

/// 이미지 카드 아래 텍스트 블록. 분류·제목·요약은 가운데, 본문은 왼쪽 정렬이다.
struct CardDetailTextSection: View {
    let card: Card

    var body: some View {
        VStack(spacing: 0) {
            Text(card.category.displayTitle)
                .font(RecapFont.pretendard(size: 14, weight: .semibold))
                .tracking(-0.28)
                .foregroundStyle(card.category.textColor)

            Text(card.title)
                .font(RecapFont.pretendard(size: 22, weight: .semibold))
                .tracking(-0.44)
                .foregroundStyle(Color.recapGray900)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 14)

            summaryBox
                .padding(.top, 14)

            Rectangle()
                .fill(Color.recapGray100)
                .frame(height: 1)
                .padding(.top, 20)

            organizedDateRow
                .padding(.top, 20)

            Text(card.memo)
                .font(RecapFont.pretendard(size: 15, weight: .medium))
                .tracking(-0.3)
                .lineSpacing(3)
                .foregroundStyle(Color.recapGray700)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 10)

            aiGeneratedNotice
                .padding(.top, 20)
        }
        .padding(.horizontal, CardDetailStyle.horizontalPadding)
        .padding(.bottom, 40)
    }

    private var summaryBox: some View {
        Text(card.summary)
            .font(RecapFont.pretendard(size: 15, weight: .medium))
            .tracking(-0.3)
            .foregroundStyle(Color.recapGray500)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .padding(10)
            .frame(maxWidth: .infinity)
            .background(Color.recapGray50)
            .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
    }

    private var organizedDateRow: some View {
        HStack(spacing: 4) {
            RecapIconView(icon: .aiEdit, size: 16, color: Color.recapGray200)

            Text(card.organizedFullDateText)
                .font(RecapFont.pretendard(size: 12, weight: .medium))
                .tracking(-0.24)
                .foregroundStyle(Color.recapGray300)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var aiGeneratedNotice: some View {
        HStack(spacing: 5) {
            RecapIconView(icon: .error, size: 16, color: Color.recapGray200)

            Text("AI가 생성한 정보예요. 일부 내용이 정확하지 않을 수 있어요.")
                .font(RecapFont.pretendard(size: 12, weight: .medium))
                .tracking(-0.24)
                .foregroundStyle(Color.recapGray300)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

}

#if DEBUG
#Preview("정보카드 텍스트") {
    ScrollView {
        CardDetailTextSection(card: Card(snapshot: SampleData.cards[1]))
    }
}
#endif
