import Foundation

enum SampleData {
    nonisolated static let cards: [InformationCard] = [
        InformationCard(
            id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
            captureID: 1,
            title: "집에서 만드는 파스타 레시피 저장아아아아아",
            summary: "재료와 조리 순서를 다시 보기 쉽게 보관",
            collection: .knowledge,
            dateText: "정리됨 2026. 06. 28",
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
            id: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
            captureID: 2,
            title: "제주 숙소 예약 정보",
            summary: "체크인 오후 3시, 8월 1박 예약이 확정된 숙소 정보 요약",
            collection: .schedule,
            dateText: "정리됨 2026. 06. 27",
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
            id: UUID(uuidString: "33333333-3333-3333-3333-333333333333")!,
            captureID: 3,
            title: "택배 반품 절차 정리",
            summary: "반품 접수, 수거 일정, 환불 조건을 한 번에 저장",
            collection: .shopping,
            dateText: "정리됨 2026. 06. 26",
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
            id: UUID(uuidString: "44444444-4444-4444-4444-444444444444")!,
            captureID: 4,
            title: "연말정산 서류 목록",
            summary: "연말정산 제출에 필요한 서류 정리",
            collection: .capture,
            dateText: "정리됨 2026. 06. 25",
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
            id: UUID(uuidString: "55555555-5555-5555-5555-555555555555")!,
            captureID: 5,
            title: "서울 삼겹살 맛집 리스트",
            summary: "서울에서 저장한 삼겹살 맛집 후보",
            collection: .place,
            dateText: "정리됨 2026. 06. 24",
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
            id: UUID(uuidString: "66666666-6666-6666-6666-666666666666")!,
            captureID: 6,
            title: "러닝 전 준비운동",
            summary: "달리기 전에 확인할 준비운동 순서",
            collection: .knowledge,
            dateText: "정리됨 2026. 06. 23",
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
            id: UUID(uuidString: "77777777-7777-7777-7777-777777777777")!,
            captureID: 7,
            title: "숙소 예약 취소 규정",
            summary: "환불 가능 기간 안내 스크린샷",
            collection: .capture,
            dateText: "정리됨 2026. 06. 22",
            location: "예약 앱",
            businessHours: "환불 규정",
            category: "기록 · 캡처",
            confirmationLabel: "환불 기한 확인",
            memo: "취소 수수료가 생기는 날짜를 따로 확인해야 함",
            tags: ["숙소예약", "취소", "환불"],
            isFavorite: false
        ),
        InformationCard(
            id: UUID(uuidString: "88888888-8888-8888-8888-888888888888")!,
            captureID: 8,
            title: "병원 예약 안내",
            summary: "진료 예약 확인 문자 스크린샷",
            collection: .schedule,
            dateText: "정리됨 2026. 06. 21",
            location: "문자 메시지",
            businessHours: "오전 10:30",
            category: "일정 · 예약",
            confirmationLabel: "방문 시간",
            memo: "방문 전 신분증 챙기기",
            tags: ["숙소예약", "병원", "예약"],
            isFavorite: false
        ),
        InformationCard(
            id: UUID(uuidString: "99999999-9999-9999-9999-999999999999")!,
            captureID: 9,
            title: "좋은 글을 쓰려면 어떻게해야",
            summary: "좋은 글을 쓰기 위한 핵심 원칙",
            collection: .content,
            dateText: "정리됨 2026. 06. 20",
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
        let display = RecapPresentation.collectionDisplay(for: kind)
        return CollectionSummary(
            kind: kind,
            count: display.sampleCount,
            previewTitle: cards.first { $0.collection == kind }?.title ?? "카드 없음"
        )
    }

    nonisolated static func cards(in kind: CollectionKind) -> [InformationCard] {
        cards.filter { $0.collection == kind }
    }

    nonisolated static func card(id: InformationCard.ID) -> InformationCard? {
        cards.first { $0.id == id }
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
