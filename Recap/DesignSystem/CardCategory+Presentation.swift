import SwiftUI

/// 분류의 화면 표기 — 이름, 아이콘 색, 글자색, 칩 팔레트. 표기가 바뀌면 여기만 고친다.
///
/// 프레젠테이션 계층의 확장이다 — `CardCategory` 선언(Models)은 자기 이름도 색도
/// 모른다. 서버 왕복도 이름이 아니라 코드(`CardTypeCode`)로 하므로, 표기가 바뀌어도
/// 달라지는 것은 눈에 보이는 것뿐이다.
///
/// 이름은 순수 문자열이라 격리 없이 어디서든 부를 수 있다.
nonisolated extension CardCategory {
    var displayTitle: String {
        switch self {
        case .shopping: "쇼핑 · 상품"
        case .place: "장소 · 맛집"
        case .schedule: "일정 · 예약"
        case .knowledge: "정보 · 지식"
        case .content: "책 · 콘텐츠"
        case .benefits: "혜택 · 이벤트"
        case .capture: "기록 · 캡처"
        case .career: "채용 · 취업"
        case .other: "기타"
        }
    }
}

/// 색은 색 토큰(`Color` 확장)이 MainActor에 묶여 있어 격리를 따른다.
extension CardCategory {
    /// 분류 아이콘 색.
    var iconColor: Color {
        switch self {
        case .shopping: .categoryBlue500
        case .place: .categoryRed500
        case .schedule: .categoryGreen500
        case .knowledge: .categoryYellow500
        case .content: .categoryPink500
        case .benefits: .categoryMint500
        case .capture: .categoryPurple500
        case .career: .categoryOrange500
        case .other: Color.recapGray200
        }
    }

    /// 분류 이름을 글자로 쓸 때의 색.
    var textColor: Color {
        switch self {
        case .shopping: .categoryBlue700
        case .place: .categoryRed700
        case .schedule: .categoryGreen700
        case .knowledge: .categoryYellow700
        case .content: .categoryPink700
        case .benefits: .categoryMint700
        case .capture: .categoryPurple700
        case .career: .categoryOrange700
        case .other: Color.recapGray500
        }
    }

    var chipPalette: CategoryChipPalette {
        switch self {
        case .shopping:
            CategoryChipPalette(background: .categoryBlue300, border: .categoryBlue500, text: .categoryBlue700)
        case .place:
            CategoryChipPalette(background: .categoryRed300, border: .categoryRed500, text: .categoryRed700)
        case .schedule:
            CategoryChipPalette(background: .categoryGreen300, border: .categoryGreen500, text: .categoryGreen700)
        case .knowledge:
            CategoryChipPalette(background: .categoryYellow300, border: .categoryYellow500, text: .categoryYellow700)
        case .content:
            CategoryChipPalette(background: .categoryPink300, border: .categoryPink500, text: .categoryPink700)
        case .benefits:
            CategoryChipPalette(background: .categoryMint300, border: .categoryMint500, text: .categoryMint700)
        case .capture:
            CategoryChipPalette(background: .categoryPurple300, border: .categoryPurple500, text: .categoryPurple700)
        case .career:
            CategoryChipPalette(background: .categoryOrange300, border: .categoryOrange500, text: .categoryOrange700)
        case .other:
            CategoryChipPalette(background: .categoryGray300, border: .categoryGray500, text: .categoryGray700)
        }
    }
}

/// 선택형 분류 칩의 배경·테두리·글자색.
struct CategoryChipPalette {
    let background: Color
    let border: Color
    let text: Color

    /// 고르지 않은 칩은 분류와 무관하게 같은 색이다.
    static let unselected = CategoryChipPalette(
        background: .white,
        border: Color.recapGray100,
        text: Color.recapGray300
    )
}
