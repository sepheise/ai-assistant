//
//  OpenAIApiKeyStoreTests.swift
//  AIAssistantTests
//
//  Created by Patricio Sepúlveda Heise on 22-06-23.
//

import XCTest
import Security

class KeychainAPIKeyStore {
    enum Error: Swift.Error {
        case invalidValue
        case saveFailure
        case loadFailure
        case updateFailure
        case deleteFailure
        case unknownError
    }

    private let key = "com.sepheise.AIAssistant.apiKey"

    func save(_ value: String) throws {
        guard let data = value.data(using: .utf8) else {
            throw Error.invalidValue
        }

        let query: [String: Any] = [
            String(kSecClass): kSecClassGenericPassword,
            String(kSecAttrAccount): key,
            String(kSecValueData): data
        ]
        let status = SecItemCopyMatching(query as CFDictionary, nil)

        switch status {
        case errSecSuccess:
            try update(query, data)
        case errSecItemNotFound:
            try add(query, data)
        default:
            throw Error.unknownError
        }
    }

    func load() throws -> String {
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: key,
            kSecReturnData: kCFBooleanTrue as Any,
            kSecMatchLimit: kSecMatchLimitOne
        ] as CFDictionary

        var queryResult: AnyObject?
        let status = SecItemCopyMatching(query, &queryResult)

        guard status == noErr, let data = queryResult as? Data else {
            throw Error.loadFailure
        }

        return String(decoding: data, as: UTF8.self)
    }

    func delete() throws {
        let query: [String: Any] = [
            String(kSecClass): kSecClassGenericPassword,
            String(kSecAttrAccount): key
        ]

        let status = SecItemDelete(query as CFDictionary)

        guard status == noErr else {
            throw Error.deleteFailure
        }
    }

    private func add(_ query: [String: Any], _ data: Data) throws {
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == noErr else {
            throw Error.saveFailure
        }
    }

    private func update(_ query: [String: Any], _ data: Data) throws {
        let attributesToUpdate: [String: Any] = [
            String(kSecValueData): data
        ]

        let status = SecItemUpdate(query as CFDictionary, attributesToUpdate as CFDictionary)
        guard status == noErr else {
            throw Error.updateFailure
        }
    }

}

class KeychainAPIKeyStoreTests: XCTestCase {
    func test_save_doesNotThrowErrorOnValidInput() {
        let anyValue = "any value"
        let sut = KeychainAPIKeyStore()

        XCTAssertNoThrow(try sut.save(anyValue))
    }

    func test_load_returnsLastSavedValue() {
        let value1 = "first value"
        let value2 = "last value"
        let sut = KeychainAPIKeyStore()

        XCTAssertNoThrow(try sut.save(value1))
        XCTAssertEqual(try sut.load(), value1)

        XCTAssertNoThrow(try sut.save(value2))
        XCTAssertEqual(try sut.load(), value2)
    }

    func test_delete_removesSavedValue() throws {
        let sut = KeychainAPIKeyStore()

        try sut.save("any value")

        XCTAssertNoThrow(try sut.delete())
        XCTAssertThrowsError(try sut.load())
    }
}
