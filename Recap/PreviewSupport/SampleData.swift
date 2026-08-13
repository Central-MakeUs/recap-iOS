#if DEBUG
import Foundation

enum SampleData {
    /// 프리뷰 고정 날짜. 표기 문자열은 `Card`의 프레젠테이션 확장이 만든다.
    nonisolated private static func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        var components = DateComponents(year: year, month: month, day: day, hour: 12)
        components.timeZone = TimeZone(identifier: "Asia/Seoul")
        return Calendar(identifier: .gregorian).date(from: components)!
    }

    nonisolated static let cards: [InformationCard] = [
        InformationCard(
            captureID: 1,
            title: "집에서 만드는 파스타 레시피 저장아아아아아",
            summary: "재료와 조리 순서를 다시 보기 쉽게 보관",
            collection: .knowledge,
            organizedAt: date(2026, 6, 28),
            location: "레시피 페이지",
            businessHours: "조리 25분",
            category: "정보 · 지식",
            confirmationLabel: nil,
            memo: "재료 목록과 삶는 시간을 따로 확인하기",
            tags: ["파스타", "레시피", "정보"],
            thumbnailAssetName: "HomeRecentPasta",
            isFavorite: false
        ),
        InformationCard(
            captureID: 2,
            title: "제주 숙소 예약 정보",
            summary: "체크인 오후 3시, 8월 1박 예약이 확정된 숙소 정보 요약",
            collection: .schedule,
            organizedAt: date(2026, 6, 27),
            location: "제주 서귀포",
            businessHours: "체크인 오후 3시",
            category: "일정 · 예약",
            confirmationLabel: "예약 확정",
            memo: "체크인 시간과 숙소 주소를 여행 전 다시 확인하기",
            tags: ["숙소예약", "제주", "체크인"],
            originalImageAssetName: "InformationCardOriginal",
            thumbnailAssetName: "HomeRecentJeju",
            isFavorite: false
        ),
        InformationCard(
            captureID: 3,
            title: "택배 반품 절차 정리",
            summary: "반품 접수, 수거 일정, 환불 조건을 한 번에 저장",
            collection: .shopping,
            organizedAt: date(2026, 6, 26),
            location: "쇼핑몰 주문내역",
            businessHours: "수거 예정 6월 30일",
            category: "쇼핑 · 상품",
            confirmationLabel: "반품 접수 완료",
            memo: "반품 접수 전 확인해야 할 절차와 준비물을 정리했습니다.",
            tags: ["택배", "반품", "쇼핑"],
            thumbnailAssetName: "HomeRecentReturn",
            isFavorite: false
        ),
        InformationCard(
            captureID: 4,
            title: "연말정산 서류 목록",
            summary: "연말정산 제출에 필요한 서류 정리",
            collection: .capture,
            organizedAt: date(2026, 6, 25),
            location: "회사 안내문",
            businessHours: "제출 기한 1월 20일",
            category: "기록 · 캡처",
            confirmationLabel: "제출 필요",
            memo: "연말정산 제출에 필요한 서류와 일정을 정리했습니다.",
            tags: ["연말정산", "서류", "캡처"],
            thumbnailAssetName: "HomeFavoriteTax",
            isFavorite: true
        ),
        InformationCard(
            captureID: 5,
            title: "서울 삼겹살 맛집 리스트",
            summary: "서울에서 저장한 삼겹살 맛집 후보",
            collection: .place,
            organizedAt: date(2026, 6, 24),
            location: "서울",
            businessHours: "영업시간 확인 필요",
            category: "장소 · 맛집",
            confirmationLabel: nil,
            memo: "방문할 삼겹살 맛집 후보를 정리했습니다.",
            tags: ["서울", "삼겹살", "맛집"],
            thumbnailAssetName: "HomeFavoriteMove",
            isFavorite: true
        ),
        InformationCard(
            captureID: 6,
            title: "러닝 전 준비운동",
            summary: "달리기 전에 확인할 준비운동 순서",
            collection: .knowledge,
            organizedAt: date(2026, 6, 23),
            location: "운동 가이드",
            businessHours: "운동 전 10분",
            category: "정보 · 지식",
            confirmationLabel: nil,
            memo: "러닝 전에 따라 할 준비운동 순서를 정리했습니다.",
            tags: ["러닝", "준비운동", "운동"],
            thumbnailAssetName: "HomeFavoriteKeyboard",
            isFavorite: true
        ),
        InformationCard(
            captureID: 7,
            title: "숙소 예약 취소 규정",
            summary: "환불 가능 기간 안내 스크린샷",
            collection: .capture,
            organizedAt: date(2026, 6, 22),
            location: "예약 앱",
            businessHours: "환불 규정",
            category: "기록 · 캡처",
            confirmationLabel: "환불 기한 확인",
            memo: "취소 수수료가 생기는 날짜를 따로 확인해야 함",
            tags: ["숙소예약", "취소", "환불"],
            isFavorite: false
        ),
        InformationCard(
            captureID: 8,
            title: "병원 예약 안내",
            summary: "진료 예약 확인 문자 스크린샷",
            collection: .schedule,
            organizedAt: date(2026, 6, 21),
            location: "문자 메시지",
            businessHours: "오전 10:30",
            category: "일정 · 예약",
            confirmationLabel: "방문 시간",
            memo: "방문 전 신분증 챙기기",
            tags: ["숙소예약", "병원", "예약"],
            isFavorite: false
        ),
        InformationCard(
            captureID: 9,
            title: "좋은 글을 쓰려면 어떻게해야",
            summary: "좋은 글을 쓰기 위한 핵심 원칙",
            collection: .content,
            organizedAt: date(2026, 6, 20),
            location: "아티클",
            businessHours: "읽기 5분",
            category: "책 · 콘텐츠",
            confirmationLabel: nil,
            memo: "좋은 글을 쓰기 위해 참고할 원칙을 정리했습니다.",
            tags: ["글쓰기", "아티클", "콘텐츠"],
            isFavorite: true
        )
    ]

    nonisolated static let recentCards: [InformationCard] = Array(cards.prefix(3))

    nonisolated static let collectionSummaries: [CollectionSummary] = CollectionKind.folderCases.map { kind in
        let recentTitles = cards
            .filter { $0.collection == kind }
            .sorted { ($0.organizedAt ?? .distantPast) > ($1.organizedAt ?? .distantPast) }
            .prefix(2)
            .map(\.title)
            .joined(separator: " · ")
        return CollectionSummary(
            kind: kind,
            count: sampleCount(for: kind),
            previewTitle: recentTitles
        )
    }

    /// 폴더 카드에 보여줄 더미 개수. 표현이 아니라 샘플 데이터라 여기에 둔다.
    nonisolated static func sampleCount(for kind: CollectionKind) -> Int {
        switch kind {
        case .shopping: 20
        case .place: 23
        case .schedule: 10
        case .knowledge: 12
        case .content: 1
        case .benefits: 5
        case .capture: 12
        case .career: 12
        case .other: 0
        }
    }

    nonisolated static func cards(in kind: CollectionKind) -> [InformationCard] {
        cards.filter { $0.collection == kind }
    }


    nonisolated static func search(_ query: String) -> [InformationCard] {
        guard !query.isEmpty else { return [] }
        return cards.filter { card in
            card.title.localizedCaseInsensitiveContains(query)
                || card.summary.localizedCaseInsensitiveContains(query)
                || card.category.localizedCaseInsensitiveContains(query)
                || card.tags.contains { $0.localizedCaseInsensitiveContains(query) }
        }
    }
}
#endif
