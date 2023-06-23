//
//  OpenAIApiKeyStoreTests.swift
//  AIAssistantTests
//
//  Created by Patricio Sepúlveda Heise on 22-06-23.
//

import XCTest
import Security

class KeychainStore {
    func save(_ value: String) throws {

    }

}

class KeychainStoreTests: XCTestCase {
    func test_save_doesNotThrowErrorOnValidInput() {
        let anyValue = "any value"
        let sut = KeychainStore()

        XCTAssertNoThrow(try sut.save(anyValue))
    }
}
