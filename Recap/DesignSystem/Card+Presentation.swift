import Foundation

/// 카드 값의 화면 표기 규칙. 표기가 바뀌면 여기만 고친다.
///
/// 프레젠테이션 계층의 확장이다 — `Card` 선언(Models)은 표기 규칙을 모른다.
extension Card {
    /// 목록 행·상세의 정리 날짜. 예: "06월 28일 정리"
    var organizedDateText: String {
        guard let organizedAt else { return "" }

        let components = Calendar.current.dateComponents([.month, .day], from: organizedAt)
        guard let month = components.month, let day = components.day else { return "" }
        return String(format: "%02d월 %02d일 정리", month, day)
    }

    /// 편집 화면의 연월일. 예: "2026. 06. 25"
    ///
    /// 다른 표기와 마찬가지로 기기 로케일과 무관한 고정 형식이다. 예전
    /// `dateText`는 로케일을 따라가 영어 기기에서 "06/25/2026"으로 나왔다.
    var fullDateText: String {
        guard let organizedAt else { return "" }

        let components = Calendar.current.dateComponents(
            [.year, .month, .day],
            from: organizedAt
        )
        guard
            let year = components.year,
            let month = components.month,
            let day = components.day
        else { return "" }
        return String(format: "%d. %02d. %02d", year, month, day)
    }
}
