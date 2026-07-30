import Foundation
import Observation

@MainActor
@Observable
final class AccountManagementModel {
    private let service: any UserAccountServing
    private let accountWithdrawalCompleted: () -> Void

    private(set) var accountInfo: UserAccountInfo?
    private(set) var isWithdrawing = false
    var toast: RecapToastContent?

    init(
        service: any UserAccountServing,
        accountWithdrawalCompleted: @escaping () -> Void
    ) {
        self.service = service
        self.accountWithdrawalCompleted = accountWithdrawalCompleted
    }

    func loadAccountInfo() async {
        do {
            accountInfo = try await service.fetchAccountInfo()
        } catch is CancellationError {
            return
        } catch {
            toast = RecapToastContent(
                style: .error,
                message: "로그인 정보를 불러오지 못했어요."
            )
        }
    }

    func withdrawAccount() async {
        guard !isWithdrawing else { return }
        isWithdrawing = true
        defer { isWithdrawing = false }

        do {
            try await service.withdrawAccount()
            accountWithdrawalCompleted()
        } catch {
            toast = RecapToastContent(
                style: .error,
                message: "회원 탈퇴에 실패했어요. 다시 시도해주세요."
            )
        }
    }
}

@MainActor
@Observable
final class DataManagementModel {
    private let service: any UserAccountServing
    private let accountDataDeleted: () -> Void

    private(set) var capturedCount = 0
    private(set) var isDeleting = false
    var toast: RecapToastContent?

    var canDeleteData: Bool {
        capturedCount > 0 && !isDeleting
    }

    init(
        service: any UserAccountServing,
        accountDataDeleted: @escaping () -> Void
    ) {
        self.service = service
        self.accountDataDeleted = accountDataDeleted
    }

    func loadDataSummary() async {
        do {
            capturedCount = try await service.fetchDataSummary().capturedCount
        } catch is CancellationError {
            return
        } catch {
            toast = RecapToastContent(
                style: .error,
                message: "데이터 정보를 불러오지 못했어요."
            )
        }
    }

    func deleteAllData() async {
        guard canDeleteData else { return }
        isDeleting = true
        defer { isDeleting = false }

        do {
            try await service.deleteAllData()
            capturedCount = 0
            accountDataDeleted()
            toast = RecapToastContent(
                style: .success,
                message: "모든 데이터를 삭제했어요."
            )
        } catch {
            toast = RecapToastContent(
                style: .error,
                message: "데이터를 삭제하지 못했어요. 다시 시도해주세요."
            )
        }
    }
}
