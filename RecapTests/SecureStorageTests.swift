import XCTest
@testable import Recap

@MainActor
final class SecureStorageTests: XCTestCase {
    func testDeviceIDIsGeneratedOnceAndThenReused() throws {
        let keychain = InMemoryKeychainDataStore()
        var generatedIDs = ["device-1", "device-2"]
        let store = KeychainSessionStore(keychain: keychain) {
            generatedIDs.removeFirst()
        }

        let firstID = try store.deviceID()
        let secondID = try store.deviceID()

        XCTAssertEqual(firstID, "device-1")
        XCTAssertEqual(secondID, "device-1")
        XCTAssertEqual(generatedIDs, ["device-2"])
        XCTAssertEqual(keychain.accounts, [SecureStorageKeychainConstants.deviceIDAccount])
    }

    func testDeletingSessionKeepsDeviceID() throws {
        let keychain = InMemoryKeychainDataStore()
        let store = KeychainSessionStore(keychain: keychain) { "stable-device" }
        let expiry = Date(timeIntervalSince1970: 1_800)

        let deviceID = try store.deviceID()
        try store.saveServerTokenRecord(
            ServerTokenRecord(
                accessToken: "access-token",
                refreshToken: "refresh-token",
                accessTokenExpiresAt: expiry
            )
        )
        try store.deleteServerTokenRecord()

        XCTAssertEqual(try store.deviceID(), deviceID)
        XCTAssertNil(try store.loadServerTokenRecord())
        XCTAssertEqual(keychain.accounts, [SecureStorageKeychainConstants.deviceIDAccount])
    }

    func testServerTokenRecordSaveLoadDeleteRoundTrip() throws {
        let store = KeychainSessionStore(keychain: InMemoryKeychainDataStore())
        let record = ServerTokenRecord(
            accessToken: "access-token",
            refreshToken: "refresh-token",
            accessTokenExpiresAt: Date(timeIntervalSince1970: 3_600)
        )

        try store.saveServerTokenRecord(record)
        XCTAssertEqual(try store.loadServerTokenRecord(), record)

        try store.deleteServerTokenRecord()
        XCTAssertNil(try store.loadServerTokenRecord())
    }

    func testServerTokenReplacementStoresOneAtomicRecord() throws {
        let keychain = InMemoryKeychainDataStore()
        let store = KeychainSessionStore(keychain: keychain)
        let first = ServerTokenRecord(
            accessToken: "old-access",
            refreshToken: "old-refresh",
            accessTokenExpiresAt: Date(timeIntervalSince1970: 3_600)
        )
        let replacement = ServerTokenRecord(
            accessToken: "new-access",
            refreshToken: "new-refresh",
            accessTokenExpiresAt: Date(timeIntervalSince1970: 7_200)
        )

        try store.saveServerTokenRecord(first)
        try store.saveServerTokenRecord(replacement)

        XCTAssertEqual(try store.loadServerTokenRecord(), replacement)
        XCTAssertEqual(keychain.writeCount(for: SecureStorageKeychainConstants.serverTokenAccount), 2)
        XCTAssertEqual(keychain.accounts, [SecureStorageKeychainConstants.serverTokenAccount])
    }

    func testReadFailureIsPropagatedWhenLoadingDeviceID() {
        let store = KeychainSessionStore(
            keychain: FailingKeychainDataStore(readError: .keychain(status: errSecInteractionNotAllowed))
        )

        XCTAssertThrowsError(try store.deviceID()) { error in
            XCTAssertEqual(error as? SecureStorageError, .keychain(status: errSecInteractionNotAllowed))
        }
    }

    func testWriteFailureIsPropagatedWhenSavingTokenRecord() {
        let store = KeychainSessionStore(
            keychain: FailingKeychainDataStore(writeError: .keychain(status: errSecNotAvailable))
        )

        XCTAssertThrowsError(
            try store.saveServerTokenRecord(
                ServerTokenRecord(
                    accessToken: "access-token",
                    refreshToken: "refresh-token",
                    accessTokenExpiresAt: Date(timeIntervalSince1970: 3_600)
                )
            )
        ) { error in
            XCTAssertEqual(error as? SecureStorageError, .keychain(status: errSecNotAvailable))
        }
    }

    func testDeleteFailureIsPropagatedWhenDeletingTokenRecord() {
        let store = KeychainSessionStore(
            keychain: FailingKeychainDataStore(deleteError: .keychain(status: errSecAuthFailed))
        )

        XCTAssertThrowsError(try store.deleteServerTokenRecord()) { error in
            XCTAssertEqual(error as? SecureStorageError, .keychain(status: errSecAuthFailed))
        }
    }
}

private final class InMemoryKeychainDataStore: KeychainDataStoring {
    private var storage: [Key: Data] = [:]
    private var writeCounts: [Key: Int] = [:]

    var accounts: [String] {
        storage.keys.map(\.account).sorted()
    }

    func read(service: String, account: String) throws -> Data? {
        storage[Key(service: service, account: account)]
    }

    func write(_ data: Data, service: String, account: String) throws {
        let key = Key(service: service, account: account)
        storage[key] = data
        writeCounts[key, default: 0] += 1
    }

    func delete(service: String, account: String) throws {
        storage.removeValue(forKey: Key(service: service, account: account))
    }

    func writeCount(for account: String) -> Int {
        writeCounts[Key(service: SecureStorageKeychainConstants.service, account: account), default: 0]
    }
}

private final class FailingKeychainDataStore: KeychainDataStoring {
    private let readError: SecureStorageError?
    private let writeError: SecureStorageError?
    private let deleteError: SecureStorageError?

    init(
        readError: SecureStorageError? = nil,
        writeError: SecureStorageError? = nil,
        deleteError: SecureStorageError? = nil
    ) {
        self.readError = readError
        self.writeError = writeError
        self.deleteError = deleteError
    }

    func read(service: String, account: String) throws -> Data? {
        if let readError {
            throw readError
        }
        return nil
    }

    func write(_ data: Data, service: String, account: String) throws {
        if let writeError {
            throw writeError
        }
    }

    func delete(service: String, account: String) throws {
        if let deleteError {
            throw deleteError
        }
    }
}

private struct Key: Hashable {
    let service: String
    let account: String
}
