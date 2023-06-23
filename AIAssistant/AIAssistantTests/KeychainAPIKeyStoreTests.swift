//
//  OpenAIApiKeyStoreTests.swift
//  AIAssistantTests
//
//  Created by Patricio Sepúlveda Heise on 22-06-23.
//

import XCTest
import AIAssistant

class KeychainAPIKeyStoreTests: XCTestCase {
    func test_save_doesNotThrowErrorOnValidInput() {
        let anyValue = "any value"
        let sut = makeSUT()

        XCTAssertNoThrow(try sut.save(anyValue))
    }

    func test_load_returnsLastSavedValue() {
        let value1 = "first value"
        let value2 = "last value"
        let sut = makeSUT()

        XCTAssertNoThrow(try sut.save(value1))
        XCTAssertEqual(try sut.load(), value1)

        XCTAssertNoThrow(try sut.save(value2))
        XCTAssertEqual(try sut.load(), value2)
    }

    func test_delete_removesSavedValue() throws {
        let sut = makeSUT()

        try sut.save("any value")

        XCTAssertNoThrow(try sut.delete())
        XCTAssertThrowsError(try sut.load())
    }

    // MARK: - Helpers

    private func makeSUT() -> KeychainAPIKeyStore {
        let sut = KeychainAPIKeyStore()
        return sut
    }
}
