//
//  ChatStoreTests.swift
//  AIAssistantTests
//
//  Created by Patricio Sepúlveda Heise on 16-06-23.
//

import XCTest
import SwiftUI
import AIAssistant

class ChatStore: ObservableObject {
    @Published var inputText: String = "" {
        didSet {
            checkCanSubmit()
        }
    }
    @Published var canSubmit: Bool = false

    private var isProcessing: Bool = false {
        didSet {
            checkCanSubmit()
        }
    }

    private let promptSender: PromptSender

    init(promptSender: PromptSender) {
        self.promptSender = promptSender
    }

    func submit() {
        guard canSubmit else { return }

        isProcessing = true
        Task {
            _ = try! await promptSender.send(prompt: inputText)
            isProcessing = false
            inputText = ""
        }
    }

    private func checkCanSubmit() {
        canSubmit = !inputText.isEmpty && !isProcessing
    }
}

class ChatStoreTests: XCTestCase {
    func test_canSubmit_whenInputTextIsNotEmptyAndIsNoProcessing() {
        let promptSenderToFinish = expectation(description: "Wait for sender to finish")
        let (sut, _) = makeSUT(expecting: promptSenderToFinish)

        // On init
        XCTAssertTrue(sut.inputText.isEmpty)
        XCTAssertFalse(sut.canSubmit)

        // Non empty text and no processing
        sut.inputText = anyNonEmptyText()
        XCTAssertTrue(sut.canSubmit)

        // When submit starts
        sut.submit()
        XCTAssertFalse(sut.canSubmit)

        // When submit finishes
        wait(for: [promptSenderToFinish], timeout: 0.1)
        XCTAssertFalse(sut.canSubmit)
    }

    func test_submit_doesNotNotifyPromptSenderWhenCantSubmit() {
        let promptSenderToNotFinish = expectation(description: "Wait for sender to finish")
        promptSenderToNotFinish.isInverted = true
        let (sut, promptSenderSpy) = makeSUT(expecting: promptSenderToNotFinish)

        sut.inputText = ""
        sut.submit()

        wait(for: [promptSenderToNotFinish], timeout: 0.1)
        XCTAssertEqual(promptSenderSpy.sentPrompts, [])
    }

    func test_submit_notifyPromptSenderWithInputText() {
        let promptSenderToFinish = expectation(description: "Wait for sender to finish")
        let expectedText = anyNonEmptyText()
        let (sut, promptSenderSpy) = makeSUT(expecting: promptSenderToFinish)

        sut.inputText = anyNonEmptyText()
        sut.submit()

        wait(for: [promptSenderToFinish], timeout: 0.1)

        XCTAssertEqual(promptSenderSpy.sentPrompts, [expectedText])
    }

    func test_submit_clearsInputTextAfterSuccessfulSubmit() {
        let promptSenderToFinish = expectation(description: "Wait for sender to finish")
        let (sut, _) = makeSUT(expecting: promptSenderToFinish)

        sut.inputText = anyNonEmptyText()
        sut.submit()

        wait(for: [promptSenderToFinish], timeout: 0.1)

        XCTAssertTrue(sut.inputText.isEmpty)
    }
}

// MARK: - Helpers

private func makeSUT(promptSenderResult: Result<PromptResponseStream, Error> = successfulResponse(), expecting expectation: XCTestExpectation) -> (sut: ChatStore, promptSenderSpy: PromptSenderSpy) {
    let promptSenderSpy = PromptSenderSpy(
        result: .success(promptResponseStream(from: ["any", " successful", " response"])),
        expectation: expectation
    )
    let sut = ChatStore(promptSender: promptSenderSpy)

    return (sut, promptSenderSpy)
}

private func successfulResponse() -> Result<PromptResponseStream, Error> {
    return .success(promptResponseStream(from: ["any", " successful", " response"]))
}

private func promptResponseStream(from textArray: [String]) -> PromptResponseStream {
    return PromptResponseStream { continuation in
        for text in textArray {
            continuation.yield(with: .success(text))
        }
        continuation.finish()
    }
}

private func anyNonEmptyText() -> String {
    return "non empty text"
}

// MARK: - Test Doubles

private class PromptSenderSpy: PromptSender {
    let result: Result<PromptResponseStream, Error>
    let expectation: XCTestExpectation
    var sentPrompts: [String] = []

    init(result: Result<PromptResponseStream, Error>, expectation: XCTestExpectation) {
        self.result = result
        self.expectation = expectation
    }

    func send(prompt: String) async throws -> PromptResponseStream {
        sentPrompts.append(prompt)
        expectation.fulfill()
        return try result.get()
    }
}
