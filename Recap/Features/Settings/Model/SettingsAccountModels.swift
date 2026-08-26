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
            toast = RecapToastMessage.accountLoadFailed.content
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
            toast = RecapToastMessage.accountWithdrawalFailed.content
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
            toast = RecapToastMessage.dataSummaryLoadFailed.content
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
            toast = RecapToastMessage.allDataDeleted.content
        } catch {
            toast = RecapToastMessage.allDataDeleteFailed.content
        }
    }
}
