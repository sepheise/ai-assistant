//
//  KeychainAPIKeyStoreTests.swift
//  AIAssistantTests
//
//  Created by Patricio Sepúlveda Heise on 22-06-23.
//

import XCTest
import AIAssistant

class KeychainAPIKeyStoreTests: XCTestCase {
    override func tearDown() async throws {
        try await clean()
    }

    func test_save_doesNotThrowErrorOnValidInput() async {
        let anyValue = "any value"
        let sut = makeSUT()

        await shouldNotThrow("on valid input") {
            try await sut.save(anyValue)
        }
    }

    func test_load_returnsLastSavedValue() async {
        let value1 = "first value"
        let value2 = "last value"
        let sut = makeSUT()

        await shouldNotThrow("when saving first value") {
            try await sut.save(value1)
        }

        await shouldNotThrow("when loading first value") {
            _ = try await sut.load()
        }

        await shouldNotThrow("when saving second value") {
            try await sut.save(value2)
        }

        var loadedValue2: String = ""

        await shouldNotThrow("when loading second value") {
            loadedValue2 = try await sut.load()
        }

        XCTAssertEqual(loadedValue2, value2)
    }

    func test_delete_removesSavedValue() async throws {
        let sut = makeSUT()

        try await sut.save("any value")

        await shouldNotThrow("on delete") {
            try await sut.delete()
        }

        await shouldThrow("on load") {
            _ = try await sut.load()
        }
    }

    // MARK: - Helpers

    private func makeSUT() -> KeychainAPIKeyStore {
        let sut = KeychainAPIKeyStore(key: "com.sepheise.AIAssistant.tests")
        return sut
    }

    private func clean() async throws {
        do {
            try await KeychainAPIKeyStore().delete()
        } catch {}
    }

    private func shouldNotThrow(_ message: String, action: () async throws -> Void) async {
        do {
            try await action()
        } catch {
            XCTFail("Shouldn't throw error \(message)")
        }
    }

    private func shouldThrow(_ message: String, action: () async throws -> Void) async {
        do {
            try await action()
            XCTFail("Should throw error \(message)")
        } catch {}
    }
}
