//
//  ChatModelTests.swift
//  AIAssistantTests
//
//  Created by Patricio Sepúlveda Heise on 16-06-23.
//

import XCTest
import AIAssistant

@MainActor
class ChatModelTests: XCTestCase {
    func test_canSubmit_whenInputTextIsNotEmptyAndIsNoProcessing() async {
        let (sut, _) = makeSUT()

        // On init
        XCTAssertTrue(sut.inputText.isEmpty)
        XCTAssertFalse(sut.canSubmit)

        // Non empty text and no processing
        sut.inputText = anyNonEmptyText()
        XCTAssertTrue(sut.canSubmit)

        await sut.submit()
        // After submit (because empty text)
        XCTAssertFalse(sut.canSubmit)

        sut.inputText = anyNonEmptyText()
        XCTAssertTrue(sut.canSubmit)
    }

    func test_submit_doesNotNotifyPromptSenderWhenCantSubmit() async {
        let (sut, promptSenderSpy) = makeSUT()

        sut.inputText = ""
        await sut.submit()

        XCTAssertEqual(promptSenderSpy.sentPrompts, [])
    }

    func test_submit_notifyPromptSenderWithInputText() async {
        let expectedText = anyNonEmptyText()
        let (sut, promptSenderSpy) = makeSUT()

        sut.inputText = anyNonEmptyText()
        await sut.submit()

        XCTAssertEqual(promptSenderSpy.sentPrompts, [expectedText])
    }

    func test_submit_clearsInputTextAfterSuccessfulSubmit() async {
        let (sut, _) = makeSUT()

        sut.inputText = anyNonEmptyText()
        await sut.submit()

        XCTAssertTrue(sut.inputText.isEmpty)
    }

    func test_submit_setsErrorMessageAndKeepsInputTextWhenPromptSenderFails() async {
        let (sut, _) = makeSUT(promptSenderResult: failedPromptSenderResponse())

        sut.inputText = anyNonEmptyText()
        await sut.submit()

        XCTAssertEqual(sut.errorMessage, "Could not load prompt response")
        XCTAssertFalse(sut.inputText.isEmpty)
    }

    func test_submit_setsResponseOnTextStream() async {
        let successfulPromptSenderResponse = successfulPromptSenderResponse(from: ["This", " is", " a", " successful", " response", "!"])
        let (sut, _) = makeSUT(promptSenderResult: successfulPromptSenderResponse)

        sut.inputText = anyNonEmptyText()
        await sut.submit()

        XCTAssertEqual(sut.responseText, "This is a successful response!")
    }
}

// MARK: - Helpers

@MainActor
private func makeSUT(promptSenderResult: Result<PromptResponseStream, SendPromptError> = successfulPromptSenderResponse()) -> (sut: ChatModel, promptSenderSpy: PromptSenderSpy) {
    let promptSenderSpy = PromptSenderSpy(
        result: promptSenderResult
    )
    let sut = ChatModel(promptSender: promptSenderSpy)

    return (sut, promptSenderSpy)
}

private func successfulPromptSenderResponse(from textArray: [String] = ["any", " successful", " response"]) -> Result<PromptResponseStream, SendPromptError> {
    return .success(promptResponseStream(from: textArray))
}

private func failedPromptSenderResponse() -> Result<PromptResponseStream, SendPromptError> {
    return .failure(.connectivity)
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
    let result: Result<PromptResponseStream, SendPromptError>
    var sentPrompts: [String] = []

    init(result: Result<PromptResponseStream, SendPromptError>) {
        self.result = result
    }

    func send(prompt: String) async throws -> PromptResponseStream {
        sentPrompts.append(prompt)
        return try result.get()
    }
}
