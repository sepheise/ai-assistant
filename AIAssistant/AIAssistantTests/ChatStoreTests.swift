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
            canSubmit = !inputText.isEmpty && !isProcessing
        }
    }
    @Published var canSubmit: Bool = false

    private var isProcessing: Bool = false {
        didSet {
            canSubmit = !inputText.isEmpty && !isProcessing
        }
    }

    private let promptSender: (String) async -> Void

    init(promptSender: @escaping (String) async -> Void) {
        self.promptSender = promptSender
    }

    func submit() {
        guard canSubmit else { return }

        isProcessing = true
        Task {
            await promptSender(inputText)
            isProcessing = false
            inputText = ""
        }
    }
}

class ChatStoreTests: XCTestCase {
    func test_canSubmit_whenInputTextIsNotEmptyAndIsNoProcessing() {
        let expectation = expectation(description: "Wait for sender to finish")
        let promptSenderSpy: (String) async -> Void = { _ in
            expectation.fulfill()
        }
        let sut = ChatStore(promptSender: promptSenderSpy)

        // On init
        XCTAssertTrue(sut.inputText.isEmpty)
        XCTAssertFalse(sut.canSubmit)

        // Non empty text and no processing
        sut.inputText = "non empty text"
        XCTAssertTrue(sut.canSubmit)

        // When submit starts
        sut.submit()
        XCTAssertFalse(sut.canSubmit)

        // When submit finishes
        wait(for: [expectation], timeout: 0.1)
        sut.inputText = ""
        XCTAssertFalse(sut.canSubmit)
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

    func test_submit_clearsInputTextAfterSuccessfulSubmit() {
        let expectation = expectation(description: "Wait for sender to finish")

        let promptSenderSpy: (String) async -> Void = { text in
            expectation.fulfill()
        }

        let sut = ChatStore(promptSender: promptSenderSpy)

        sut.inputText = "non empty text"
        sut.submit()

        wait(for: [expectation], timeout: 0.1)

        XCTAssertTrue(sut.inputText.isEmpty)
    }
}
