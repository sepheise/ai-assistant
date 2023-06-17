//
//  OpenAIMessageSenderTests.swift
//  AIAssistantTests
//
//  Created by Patricio Sepúlveda Heise on 30-05-23.
//

import XCTest
import AIAssistant

class OpenAIMessageSenderTests: XCTestCase {
    func test_init_doesNotSendAnyRequest() {
        let (_, client) = makeSUT()

        XCTAssertEqual(client.sentRequests, [], "Should not perform any request")
    }

    func test_send_startRequestWithAllNecessaryParametersDefaultOptionsAndTextInput() async throws {
        let url = anyURL()
        let apiKey = anySecretKey()
        let textInput = anyTextInput()
        let (sut, client) = makeSUT(url: url, apiKey: apiKey)

        _ = try await sut.send(prompt: textInput)

        XCTAssertEqual(client.sentRequests.count, 1)
        XCTAssertEqual(client.sentRequests.first?.url, url)
        XCTAssertEqual(client.sentRequests.first?.httpMethod, "POST")
        XCTAssertEqual(client.sentRequests.first?.value(forHTTPHeaderField: "Content-Type"), "application/json")
        XCTAssertEqual(client.sentRequests.first?.value(forHTTPHeaderField: "Authorization"), "Bearer \(apiKey)")

        let expectedBody = httpBody(
            model: "gpt-3.5-turbo",
            stream: true,
            messages: [["role": "user", "content": "\(textInput)"]]
        )

        XCTAssertEqual(client.sentRequests.first?.httpBody, expectedBody)
    }

    func test_send_includePreviousMessages() async throws {
        let textInput = anyTextInput()
        let previousMessages: [Message] = [
            Message(role: .user, content: "message 1"),
            Message(role: .assistant, content: "message 2")
        ]
        let expectedBody = httpBody(messages: [
            ["role": "user", "content": "message 1"],
            ["role": "assistant", "content": "message 2"],
            ["role": "user", "content": "\(textInput)"]
        ])
        let (sut, client) = makeSUT(previousMessages: previousMessages)

        _ = try await sut.send(prompt: textInput)

        XCTAssertEqual(client.sentRequests.first?.httpBody, expectedBody)
    }

    func test_send_deliversInvalidInputErrorOnInputExceedingCharacterLimit() async {
        let textInput = "Adding this text exceeds character limit"
        let threeThousandCharactersString = String(repeating: "a", count: 3000)
        let previousMessages: [Message] = [
            Message(role: .assistant, content: threeThousandCharactersString)
        ]
        let (sut, client) = makeSUT(previousMessages: previousMessages)

        do {
            _ = try await sut.send(prompt: textInput)
            XCTFail("Expected error: \(SendPromptError.invalidInput)")
        } catch {
            XCTAssertEqual(error as? SendPromptError, .invalidInput)
        }

        XCTAssertEqual(client.sentRequests.count, 0)
    }

    func test_send_deliversConnectivityErrorOnRequestError() async {
        let textInput = anyTextInput()
        let (sut, _) = makeSUT(clientResult: .failure(NSError(domain: "an error", code: 0)))

        do {
            _ = try await sut.send(prompt: textInput)
            XCTFail("Expected error: \(SendPromptError.connectivity)")
        } catch {
            XCTAssertEqual(error as? SendPromptError, .connectivity)
        }
    }

    func test_send_deliversUnexpectedResponseErrorWhenStatusIsDifferentThan200() async {
        let textInput = anyTextInput()
        let linesStream = anyValidLinesStream()
        let response = HTTPURLResponse(url: anyURL(), statusCode: 404, httpVersion: nil, headerFields: nil)!
        let (sut, _) = makeSUT(clientResult: .success((linesStream, response)))

        do {
            _ = try await sut.send(prompt: textInput)
            XCTFail("Expected error: \(SendPromptError.unexpectedResponse)")
        } catch {
            XCTAssertEqual(error as? SendPromptError, .unexpectedResponse)
        }
    }

    func test_send_deliversUnexpectedResponseErrorWhenLineDontStartWithData() async {
        let textInput = anyTextInput()
        let anySuccessfulResponse = successfulHTTPURLResponse()
        let invalidLinesStream = linesStream(from: ["invalid line"])
        let (sut, _) = makeSUT(clientResult: .success((invalidLinesStream, anySuccessfulResponse)))

        guard let textStream = try? await sut.send(prompt: textInput) else {
            XCTFail("Expected to get the text stream")
            return
        }

        do {
            for try await _ in textStream {}
        } catch {
            XCTAssertEqual(error as? SendPromptError, .unexpectedResponse)
        }
    }

    func test_send_deliversTextOnSuccessfullyParsedText() async throws {
        let textInput = anyTextInput()
        let expectedText = "Hello there!"
        let anySuccessfulResponse = successfulHTTPURLResponse()
        let validLinesStream = linesStream(from: validResponseLines())
        let (sut, _) = makeSUT(clientResult: .success((validLinesStream, anySuccessfulResponse)))

        let textStream = try await sut.send(prompt: textInput)

        var receivedText = ""
        for try await text in textStream {
            receivedText += text
        }

        XCTAssertEqual(receivedText, expectedText)
    }

    func test_send_deliversIncompleteResponseErrorWhenTerminationIsNotReceived() async throws {
        let textInput = anyTextInput()
        let incompleteLinesStream = incompleteLinesStream()
        let anySuccessfulResponse = successfulHTTPURLResponse()
        let (sut, _) = makeSUT(clientResult: .success((incompleteLinesStream, anySuccessfulResponse)))

        let textStream = try await sut.send(prompt: textInput)

        do {
            for try await _ in textStream {}
            XCTFail("Expected error \(SendPromptError.incompleteResponse)")
        } catch {
            XCTAssertEqual(error as? SendPromptError, .incompleteResponse)
        }
    }
}

// MARK: Helpers

private func makeSUT(
    url: URL = anyURL(),
    apiKey: String = anySecretKey(),
    previousMessages: [Message] = [],
    clientResult: Result<(HTTPClient.LinesStream, URLResponse), Error> = .success((anyValidLinesStream(), successfulHTTPURLResponse()))
) -> (sut: PromptSender, client: HTTPClientSpy) {
    let client = HTTPClientSpy(result: clientResult)
    let sut = OpenAIMessageSender(client: client, url: url, apiKey: apiKey, previousMessages: previousMessages)

    return (sut, client)
}

private func linesStream(from lines: [String]) -> HTTPClient.LinesStream {
    return HTTPClient.LinesStream { continuation in
        for line in lines {
            continuation.yield(with: .success(line))
        }
        continuation.finish()
    }
}

private func httpBody(model: String = "gpt-3.5-turbo", stream: Bool = true, messages: [[String: Any]] = []) -> Data {
    let bodyJSON: [String: Any] = [
        "model": model,
        "stream": stream,
        "messages": messages
    ]
    let bodyData = try! JSONSerialization.data(withJSONObject: bodyJSON, options: [.sortedKeys])
    return bodyData
}

private func anySecretKey() -> String {
    return "some secret key"
}

private func anyURL() -> URL {
    return URL(string: "http://any-url.com")!
}

private func anyTextInput() -> String {
    return "any text input"
}

private func successfulHTTPURLResponse() -> HTTPURLResponse {
    return HTTPURLResponse(url: anyURL(), statusCode: 200, httpVersion: nil, headerFields: nil)!
}

private func anyValidLinesStream() -> HTTPClient.LinesStream {
    return linesStream(from: validResponseLines())
}

private func incompleteLinesStream() -> HTTPClient.LinesStream {
    return linesStream(from: [
        """
        data: {"id":"chatcmpl-7Jgsv2kvsTBdl1KYYooO17tDRLvKm","object":"chat.completion.chunk","created":1684927437,"model":"gpt-3.5-turbo-0301","choices":[{"delta":{"role":"assistant"},"index":0,"finish_reason":null}]}
        """,
        """
        data: {"id":"chatcmpl-7Jgsv2kvsTBdl1KYYooO17tDRLvKm","object":"chat.completion.chunk","created":1684927437,"model":"gpt-3.5-turbo-0301","choices":[{"delta":{"content":"Hello"},"index":0,"finish_reason":null}]}
        """
    ])
}

private func validResponseLines() -> [String] {
    return [
        """
        data: {"id":"chatcmpl-7Jgsv2kvsTBdl1KYYooO17tDRLvKm","object":"chat.completion.chunk","created":1684927437,"model":"gpt-3.5-turbo-0301","choices":[{"delta":{"role":"assistant"},"index":0,"finish_reason":null}]}
        """,
        """
        data: {"id":"chatcmpl-7Jgsv2kvsTBdl1KYYooO17tDRLvKm","object":"chat.completion.chunk","created":1684927437,"model":"gpt-3.5-turbo-0301","choices":[{"delta":{"content":"Hello"},"index":0,"finish_reason":null}]}
        """,
        """
        data: {"id":"chatcmpl-7Jgsv2kvsTBdl1KYYooO17tDRLvKm","object":"chat.completion.chunk","created":1684927437,"model":"gpt-3.5-turbo-0301","choices":[{"delta":{"content":" there"},"index":0,"finish_reason":null}]}
        """,
        """
        data: {"id":"chatcmpl-7Jgsv2kvsTBdl1KYYooO17tDRLvKm","object":"chat.completion.chunk","created":1684927437,"model":"gpt-3.5-turbo-0301","choices":[{"delta":{"content":"!"},"index":0,"finish_reason":null}]}
        """,
        """
        data: {"id":"chatcmpl-7Jgsv2kvsTBdl1KYYooO17tDRLvKm","object":"chat.completion.chunk","created":1684927437,"model":"gpt-3.5-turbo-0301","choices":[{"delta":{},"index":0,"finish_reason":"stop"}]}
        """,
        """
        data: [DONE]
        """
    ]
}

// MARK: Test Doubles

private class HTTPClientSpy: HTTPClient {
    private(set) var sentRequests = [URLRequest]()
    let result: Result<(HTTPClient.LinesStream, URLResponse), Error>

    init(result: Result<(HTTPClient.LinesStream, URLResponse), Error>) {
        self.result = result
    }

    func lines(from urlRequest: URLRequest) throws -> (HTTPClient.LinesStream, URLResponse) {
        sentRequests.append(urlRequest)
        return try result.get()
    }
}
