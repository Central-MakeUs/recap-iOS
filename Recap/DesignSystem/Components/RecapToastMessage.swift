import Foundation

/// 앱이 토스트로 띄우는 문구를 한곳에 모은다.
///
/// 같은 동작인데 화면마다 문구가 갈리는 일을 막는다. 실제로 즐겨찾기 해제가
/// "해제"와 "삭제"로 나뉘어 있었다.
///
/// 각 항목의 `content`가 성공·실패 스타일까지 정하므로 호출부는 상황만 고르면 된다.
enum RecapToastMessage {
    // MARK: 즐겨찾기

    case favoriteAdded
    case favoriteRemoved
    case favoriteAddFailed
    case favoriteRemoveFailed

    // MARK: 스크린샷 삭제

    case screenshotDeleted
    case screenshotsDeleted(count: Int)
    case screenshotDeleteFailed

    // MARK: 카드 편집·신고

    case cardSaveFailed
    case reportAccepted
    case reportFailed

    // MARK: 로그인

    case loginFailed

    // MARK: 설정 — 계정·데이터

    case accountLoadFailed
    case accountWithdrawalFailed
    case dataSummaryLoadFailed
    case allDataDeleted
    case allDataDeleteFailed

    // MARK: AI 데이터 전송 동의

    case aiConsentLoadFailed
    case aiConsentSaveFailed
    case aiConsentRevoked
    case aiConsentRevokeFailed

    var content: RecapToastContent {
        switch self {
        case .favoriteAdded:
            .init(style: .success, message: "즐겨찾기에 추가했어요.")
        case .favoriteRemoved:
            // "즐겨찾기에서 삭제"는 카드를 지우는 동작(`screenshotDeleted`)과 헷갈린다.
            // 즐겨찾기 해제는 카드가 그대로 남으므로 "해제"로 쓴다.
            .init(style: .success, message: "즐겨찾기를 해제했어요.")
        case .favoriteAddFailed:
            .init(style: .error, message: "즐겨찾기에 추가하지 못했어요. 다시 시도해주세요.")
        case .favoriteRemoveFailed:
            .init(style: .error, message: "즐겨찾기를 해제하지 못했어요. 다시 시도해주세요.")

        case .screenshotDeleted:
            .init(style: .success, message: "스크린샷을 삭제했어요.")
        case .screenshotsDeleted(let count):
            .init(style: .success, message: "\(count)개의 스크린샷을 삭제했어요.")
        case .screenshotDeleteFailed:
            .init(style: .error, message: "스크린샷을 삭제하지 못했어요. 다시 시도해주세요.")

        case .cardSaveFailed:
            .init(style: .error, message: "스크린샷 정보를 저장하지 못했어요. 다시 시도해주세요.")
        case .reportAccepted:
            .init(style: .success, message: "신고가 접수됐어요. 검토 후 개선에 반영할게요.")
        case .reportFailed:
            .init(style: .error, message: "신고를 접수하지 못했어요. 다시 시도해주세요.")

        case .loginFailed:
            .init(style: .error, message: "로그인에 실패했어요. 잠시 후 다시 시도해주세요.")

        case .accountLoadFailed:
            .init(style: .error, message: "로그인 정보를 불러오지 못했어요.")
        case .accountWithdrawalFailed:
            .init(style: .error, message: "회원 탈퇴에 실패했어요. 다시 시도해주세요.")
        case .dataSummaryLoadFailed:
            .init(style: .error, message: "데이터 정보를 불러오지 못했어요.")
        case .allDataDeleted:
            .init(style: .success, message: "모든 데이터를 삭제했어요.")
        case .allDataDeleteFailed:
            .init(style: .error, message: "데이터를 삭제하지 못했어요. 다시 시도해주세요.")

        case .aiConsentLoadFailed:
            .init(style: .error, message: "AI 데이터 전송 동의 상태를 불러오지 못했어요.")
        case .aiConsentSaveFailed:
            .init(style: .error, message: "AI 데이터 전송 동의를 저장하지 못했어요.")
        case .aiConsentRevoked:
            .init(style: .success, message: "AI 데이터 전송 동의를 철회했어요.")
        case .aiConsentRevokeFailed:
            .init(style: .error, message: "AI 데이터 전송 동의를 철회하지 못했어요.")
        }
    }

    /// 즐겨찾기 토글 결과. 네 화면이 같은 문구를 쓰도록 한곳에서 고른다.
    static func favoriteToggled(isFavorite: Bool) -> RecapToastMessage {
        isFavorite ? .favoriteAdded : .favoriteRemoved
    }

    /// 토글 실패. 결과를 모르므로 시도 전 상태로 방향을 정한다.
    static func favoriteToggleFailed(wasFavorite: Bool) -> RecapToastMessage {
        wasFavorite ? .favoriteRemoveFailed : .favoriteAddFailed
    }
}
