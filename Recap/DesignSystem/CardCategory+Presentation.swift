import Foundation

/// 분류의 화면 표기. 표기가 바뀌면 여기만 고친다.
///
/// 프레젠테이션 계층의 확장이다 — `CardCategory` 선언(Models)은 자기 이름을
/// 모른다. 서버 왕복도 이름이 아니라 코드(`CardTypeCode`)로 하므로, 이름이
/// 바뀌어도 달라지는 것은 눈에 보이는 글자뿐이다.
///
/// 색상·아이콘까지 함께 필요하면 `RecapPresentation.categoryDisplay`를 쓴다.
/// 순수 문자열이라 격리 없이 어디서든 부를 수 있게 `nonisolated`로 둔다.
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
