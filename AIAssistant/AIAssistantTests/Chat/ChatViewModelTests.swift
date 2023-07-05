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

        XCTAssertEqual(promptSenderSpy.sentParameters.count, 1)
    }

    func test_submit_canRunSequentially() async {
        let (sut, promptSenderSpy) = makeSUT()

        sut.inputText = anyNonEmptyText()
        await sut.submit()

        sut.inputText = anyNonEmptyText()
        await sut.submit()

        XCTAssertEqual(promptSenderSpy.sentParameters.count, 2)
    }

    func test_submit_doesNotNotifyPromptSenderWhenCantSubmit() async {
        let (sut, promptSenderSpy) = makeSUT()

        sut.inputText = ""
        await sut.submit()

        XCTAssertEqual(promptSenderSpy.sentParameters, [])
    }

    func test_submit_notifyPromptSenderWithInputTextAndPreviousMessages() async {
        let firstPrompt = anyNonEmptyText()
        let (sut, promptSenderSpy) = makeSUT()

        sut.inputText = firstPrompt
        await sut.submit()

        XCTAssertEqual(promptSenderSpy.sentParameters, [SentParameters(prompt: firstPrompt, previousMessages: [])])

        let secondPrompt = "another prompt"
        sut.inputText = secondPrompt
        await sut.submit()

        XCTAssertEqual(promptSenderSpy.sentParameters, [
            SentParameters(prompt: firstPrompt, previousMessages: []),
            SentParameters(prompt: secondPrompt, previousMessages: [
                Message(role: .user, content: firstPrompt),
                Message(role: .assistant, content: "any successful response")
            ])
        ])
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
        let firstPrompt = anyNonEmptyText()
        let firstResult = successfulPromptSenderResult(from: ["This", " is", " a", " successful", " response", "!"])
        let (sut, promptSenderSpy) = makeSUT(promptSenderResult: firstResult)

        sut.inputText = firstPrompt
        await sut.submit()

        let secondPrompt = "another prompt"
        let secondResult = successfulPromptSenderResult(from: ["This", " is", " another", " successful", " response", "!"])
        promptSenderSpy.result = secondResult

        sut.inputText = secondPrompt
        await sut.submit()

        let expectedPromptResponses = [
            PromptResponse(id: 0, prompt: firstPrompt, response: "This is a successful response!"),
            PromptResponse(id: 1, prompt: secondPrompt, response: "This is another successful response!")
        ]

        XCTAssertEqual(sut.promptResponses, expectedPromptResponses)
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
    var sentParameters: [SentParameters] = []
    var sentPrompts: [Prompt] = []

    init(result: Result<PromptResponseStream, SendPromptError>) {
        self.result = result
    }

    func send(prompt: AIAssistant.Prompt) async throws -> AIAssistant.PromptResponseStream {
        sentPrompts.append(prompt)
        return try result.get()
    }

    func send(prompt: String, previousMessages: [Message] = []) async throws -> PromptResponseStream {
        sentParameters.append(SentParameters(prompt: prompt, previousMessages: previousMessages))
        return try result.get()
    }
}

private struct SentParameters: Equatable {
    let prompt: String
    let previousMessages: [Message]

    static func == (lhs: SentParameters, rhs: SentParameters) -> Bool {
        lhs.prompt == rhs.prompt && lhs.previousMessages == rhs.previousMessages
    }
}
