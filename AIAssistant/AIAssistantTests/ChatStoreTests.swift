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

    let promptSender: (String) async -> Void

    init(promptSender: @escaping (String) async -> Void) {
        self.promptSender = promptSender
    }

    func submit() {
        guard canSubmit else { return }

        Task {
            await promptSender(inputText)
        }
    }
}

class ChatStoreTests: XCTestCase {
    func test_canSubmit_whenInputTextIsNotEmpty() {
        let sut = ChatStore(promptSender: { _ in })

        sut.inputText = ""

        XCTAssertFalse(sut.canSubmit)

        sut.inputText = "non empty text"

        XCTAssertTrue(sut.canSubmit)
    }

    func test_submit_doesNotNotifyPromptSenderWhenCantSubmit() {
        let expectation = expectation(description: "Wait for sender to finish")
        expectation.isInverted = true

        var promptSenderCalls: [String] = []
        let promptSenderSpy: (String) async -> Void = { text in
            promptSenderCalls.append(text)
            expectation.fulfill()
            XCTFail("Expected to not complete")
        }

        let sut = ChatStore(promptSender: promptSenderSpy)

        sut.inputText = ""
        sut.submit()

        wait(for: [expectation], timeout: 0.1)

        XCTAssertEqual(promptSenderCalls, [])
    }

    func test_submit_notifyPromptSenderWithInputText() {
        let expectation = expectation(description: "Wait for sender to finish")

        var promptSenderCalls: [String] = []
        let promptSenderSpy: (String) async -> Void = { text in
            promptSenderCalls.append(text)
            expectation.fulfill()
        }

        let sut = ChatStore(promptSender: promptSenderSpy)

        sut.inputText = "non empty text"
        sut.submit()

        wait(for: [expectation], timeout: 0.1)

        XCTAssertEqual(promptSenderCalls, ["non empty text"])
    }
}
