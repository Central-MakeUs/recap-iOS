import Foundation

/// 정리 결과 화면의 상태. 앱과 공유 확장이 함께 쓴다.
enum CardCreationResultState: Hashable {
    case complete
    case partialFailure
    case failure

    func title(selectedCount: Int, failedCount: Int) -> String {
        switch self {
        case .complete:
            "\(selectedCount)개의 스크린샷을\n정리했어요"
        case .partialFailure:
            "일부 스크린샷을 정리하지 못했어요"
        case .failure:
            "스크린샷을 정리하지 못했어요"
        }
    }

    var message: String {
        switch self {
        case .complete:
            "보관함에서 확인해보세요!"
        case .partialFailure:
            "정리된 스크린샷은\n보관함에 저장했어요!"
        case .failure:
            "다음에 다시 시도해주세요."
        }
    }

    var buttonTitle: String {
        self == .complete ? "완료" : "닫기"
    }
}
