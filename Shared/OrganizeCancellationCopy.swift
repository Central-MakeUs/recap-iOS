import Foundation

/// 정리 취소 확인 문구. 앱 플로우와 공유 확장 다이얼로그가 함께 쓴다.
///
/// 다이얼로그 UI는 아직 두 벌이지만(#96에서 화면만 합쳤다) 문구만은
/// 한곳에 둬서 한쪽만 고쳐지는 일을 막는다.
enum OrganizeCancellationCopy {
    static let title = "정리를 취소할까요?"
    static let message = "지금 나가면 공유한 스크린샷이\n정리되지 않아요"
    static let continueTitle = "계속정리하기"
    static let exitTitle = "나가기"
}
