//
//  ChatViewModelTests.swift
//  AIAssistantTests
//
//  Created by Patricio Sepúlveda Heise on 16-06-23.
//

import XCTest
import AIAssistant

@MainActor
class ChatViewModelTests: XCTestCase {
    func test_cantSubmit_whenInputTextIsEmpty() async {
        let (sut, _) = makeSUT()

        sut.inputText = ""

        XCTAssertFalse(sut.canSubmit)
    }

    func test_submit_cantSubmitMoreThanOnceAtTheSameTime() async {
        let (sut, promptSenderSpy) = makeSUT()

        sut.inputText = anyNonEmptyText()

        async let firstExec: () = sut.submit()
        async let secondExec: () = sut.submit()
        async let thirdExec: () = sut.submit()

        _ = await [firstExec, secondExec, thirdExec]

        XCTAssertEqual(promptSenderSpy.sentPrompts.count, 1)
    }

    func test_submit_canRunSequentially() async {
        let (sut, promptSenderSpy) = makeSUT()

        sut.inputText = anyNonEmptyText()
        await sut.submit()

        sut.inputText = anyNonEmptyText()
        await sut.submit()

        XCTAssertEqual(promptSenderSpy.sentPrompts.count, 2)
    }

    func test_submit_doesNotNotifyPromptSenderWhenCantSubmit() async {
        let (sut, promptSenderSpy) = makeSUT()

        sut.inputText = ""
        await sut.submit()

        XCTAssertEqual(promptSenderSpy.sentPrompts, [])
    }

    func test_submit_notifyPromptSenderWithInputTextAndPreviousMessages() async {
        let firstPromptText = anyNonEmptyText()
        let (sut, promptSenderSpy) = makeSUT()

        sut.inputText = firstPromptText
        await sut.submit()

        XCTAssertEqual(promptSenderSpy.sentPrompts.count, 1)
        XCTAssertEqual(promptSenderSpy.sentPrompts.first?.content, firstPromptText)

        let secondPromptText = "another prompt text"
        sut.inputText = secondPromptText
        await sut.submit()

        XCTAssertEqual(promptSenderSpy.sentPrompts.count, 2)
        XCTAssertEqual(promptSenderSpy.sentPrompts[0].content, firstPromptText)
        XCTAssertEqual(promptSenderSpy.sentPrompts[0].previousPrompts, [])
        XCTAssertEqual(promptSenderSpy.sentPrompts[1].content, secondPromptText)
        XCTAssertEqual(promptSenderSpy.sentPrompts[1].previousPrompts.count, 1)
        XCTAssertEqual(promptSenderSpy.sentPrompts[1].previousPrompts[0].content, firstPromptText)
    }

    func test_submit_clearsInputTextAfterSuccessfulSubmit() async {
        let (sut, _) = makeSUT()

        sut.inputText = anyNonEmptyText()
        await sut.submit()

        XCTAssertTrue(sut.inputText.isEmpty)
    }

    func test_submit_setsErrorMessageWhenPromptSenderFails() async {
        let (sut, _) = makeSUT(promptSenderResult: failedPromptSenderResult())

        sut.inputText = anyNonEmptyText()
        await sut.submit()

        XCTAssertEqual(sut.errorMessage, "Could not load prompt response")
    }

    func test_submit_storesPromptResponsesWhenFetchedTextStreamSuccessfully() async {
        let firstPromptText = anyNonEmptyText()
        let firstResult = successfulPromptSenderResult(from: ["This", " is", " a", " successful", " response", "!"])
        let (sut, promptSenderSpy) = makeSUT(promptSenderResult: firstResult)

        sut.inputText = firstPromptText
        await sut.submit()

        let secondPromptText = "another prompt"
        let secondResult = successfulPromptSenderResult(from: ["This", " is", " another", " successful", " response", "!"])
        promptSenderSpy.result = secondResult

        sut.inputText = secondPromptText
        await sut.submit()

        XCTAssertEqual(sut.prompts.count, 2)
        XCTAssertEqual(sut.prompts[0].content, firstPromptText)
        XCTAssertEqual(sut.prompts[0].completion?.content, "This is a successful response!")
        XCTAssertEqual(sut.prompts[1].content, secondPromptText)
        XCTAssertEqual(sut.prompts[1].completion?.content, "This is another successful response!")
    }
}

// MARK: - Helpers

@MainActor
private func makeSUT(promptSenderResult: Result<PromptResponseStream, SendPromptError> = successfulPromptSenderResult()) -> (sut: ChatViewModel, promptSenderSpy: PromptSenderSpy) {
    let promptSenderSpy = PromptSenderSpy(
        result: promptSenderResult
    )
    let sut = ChatViewModel(promptSender: promptSenderSpy)

    return (sut, promptSenderSpy)
}

private func successfulPromptSenderResult(from textArray: [String] = ["any", " successful", " response"]) -> Result<PromptResponseStream, SendPromptError> {
    return .success(promptResponseStream(from: textArray))
}

private func failedPromptSenderResult() -> Result<PromptResponseStream, SendPromptError> {
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
    var result: Result<PromptResponseStream, SendPromptError>
    var sentPrompts: [Prompt] = []

    init(result: Result<PromptResponseStream, SendPromptError>) {
        self.result = result
    }

    func send(prompt: AIAssistant.Prompt) async throws -> AIAssistant.PromptResponseStream {
        sentPrompts.append(prompt)
        return try result.get()
    }
}
