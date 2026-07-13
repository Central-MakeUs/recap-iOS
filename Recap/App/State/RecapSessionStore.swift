import Foundation
import Observation

nonisolated enum SessionSignOutReason: Equatable, Sendable {
    case sessionExpired
    case authenticationFailed
    case secureStorageFailed
}

nonisolated enum RecapSessionState: Equatable, Sendable {
    case launching
    case signedOut(SessionSignOutReason?)
    case authenticating(AuthProvider)
    case authenticated(ServerTokenRecord)
    case signingOut
}

nonisolated enum LoginAttemptOutcome: Equatable, Sendable {
    case success
    case cancelled
    case failure
    case ignored
}

@MainActor
@Observable
final class RecapSessionStore {
    private(set) var state: RecapSessionState

    private let authenticationService: AuthenticationService
    private let secureSessionStore: any SecureSessionStoring
    private let minimumAccessTokenValidity: TimeInterval

    @ObservationIgnored
    private var authenticationTask: Task<ServerTokenRecord, Error>?

    @ObservationIgnored
    private var authenticationAttemptID: UUID?

    init(
        authenticationService: AuthenticationService,
        secureSessionStore: any SecureSessionStoring,
        minimumAccessTokenValidity: TimeInterval = 30,
        initialState: RecapSessionState = .launching
    ) {
        self.authenticationService = authenticationService
        self.secureSessionStore = secureSessionStore
        self.minimumAccessTokenValidity = minimumAccessTokenValidity
        self.state = initialState
    }

    func restore(now: Date = Date()) {
        state = .launching

        do {
            guard let tokenRecord = try secureSessionStore.loadServerTokenRecord() else {
                state = .signedOut(nil)
                return
            }

            guard tokenRecord.accessTokenExpiresAt.timeIntervalSince(now) > minimumAccessTokenValidity else {
                try secureSessionStore.deleteServerTokenRecord()
                state = .signedOut(.sessionExpired)
                return
            }

            state = .authenticated(tokenRecord)
        } catch {
            try? secureSessionStore.deleteServerTokenRecord()
            state = .signedOut(.secureStorageFailed)
        }
    }

    func login(using provider: any SocialLoginProviding) async -> LoginAttemptOutcome {
        guard authenticationTask == nil else { return .ignored }

        let attemptID = UUID()
        authenticationAttemptID = attemptID
        state = .authenticating(provider.provider)

        let task = Task { @MainActor [authenticationService] in
            try await authenticationService.login(using: provider)
        }
        authenticationTask = task

        do {
            let tokenRecord = try await task.value
            guard authenticationAttemptID == attemptID else {
                try? secureSessionStore.deleteServerTokenRecord()
                return .cancelled
            }

            state = .authenticated(tokenRecord)
            authenticationAttemptID = nil
            authenticationTask = nil
            return .success
        } catch is CancellationError {
            if authenticationAttemptID == attemptID {
                state = .signedOut(nil)
            }
            finishAuthenticationAttempt(attemptID)
            return .cancelled
        } catch let error as SocialLoginError where error == .cancelled {
            if authenticationAttemptID == attemptID {
                state = .signedOut(nil)
            }
            finishAuthenticationAttempt(attemptID)
            return .cancelled
        } catch {
            if authenticationAttemptID == attemptID {
                state = .signedOut(.authenticationFailed)
            } else {
                try? secureSessionStore.deleteServerTokenRecord()
            }
            finishAuthenticationAttempt(attemptID)
            return .failure
        }
    }

    private func finishAuthenticationAttempt(_ attemptID: UUID) {
        if authenticationAttemptID == attemptID {
            authenticationAttemptID = nil
            authenticationTask = nil
        }
    }

    func logout() {
        state = .signingOut
        authenticationAttemptID = nil
        authenticationTask?.cancel()
        authenticationTask = nil

        do {
            try secureSessionStore.deleteServerTokenRecord()
            state = .signedOut(nil)
        } catch {
            state = .signedOut(.secureStorageFailed)
        }
    }
}
