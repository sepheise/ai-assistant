//
//  ChatStoreTests.swift
//  AIAssistantTests
//
//  Created by Patricio Sepúlveda Heise on 16-06-23.
//

import XCTest
import SwiftUI

class ChatStore: ObservableObject {
    @Published var inputText: String = "" {
        didSet {
            canSubmit = !inputText.isEmpty
        }
    }
    @Published var canSubmit: Bool = false
}

class ChatStoreTests: XCTestCase {
    func test_canSubmit_whenInputTextIsNotEmpty() {
        let sut = ChatStore()

        sut.inputText = ""

        XCTAssertFalse(sut.canSubmit)

        sut.inputText = "not empty text"

        XCTAssertTrue(sut.canSubmit)
    }
}
