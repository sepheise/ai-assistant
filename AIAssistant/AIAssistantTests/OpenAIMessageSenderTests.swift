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
        let url = URL(string: "http://any-url.com")!
        let apiKey = anySecretKey()
        let textInput = "any message"
        let (sut, client) = makeSUT(url: url, apiKey: apiKey)

        _ = try await sut.send(text: textInput)

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
        let textInput = "any message"
        let previousMessages: [Message] = [
            Message(role: "system", content: "message 1"),
            Message(role: "user", content: "message 2"),
            Message(role: "assistant", content: "message 3")
        ]
        let expectedBody = httpBody(messages: [
            ["role": "system", "content": "message 1"],
            ["role": "user", "content": "message 2"],
            ["role": "assistant", "content": "message 3"],
            ["role": "user", "content": "\(textInput)"]
        ])
        let (sut, client) = makeSUT(previousMessages: previousMessages)

        _ = try await sut.send(text: textInput)

        XCTAssertEqual(client.sentRequests.first?.httpBody, expectedBody)
    }

    func test_send_deliversInvalidInputErrorOnInputExceedingCharacterLimit() async {
        let textInput = "Adding this text exceeds character limit"
        let threeThousandCharactersString = String(repeating: "a", count: 3000)
        let previousMessages: [Message] = [
            Message(role: "assistant", content: threeThousandCharactersString)
        ]
        let (sut, client) = makeSUT(previousMessages: previousMessages)

        do {
            _ = try await sut.send(text: textInput)
            XCTFail("Expected error: \(SendMessageError.invalidInput)")
        } catch {
            XCTAssertEqual(error as? SendMessageError, .invalidInput)
        }

        XCTAssertEqual(client.sentRequests.count, 0)
    }

    func test_send_deliversConnectivityErrorOnRequestError() async {
        let textInput = "any message"
        let (sut, _) = makeSUT(clientResult: .failure(NSError(domain: "an error", code: 0)))

        do {
            _ = try await sut.send(text: textInput)
            XCTFail("Expected error: \(SendMessageError.connectivity)")
        } catch {
            XCTAssertEqual(error as? SendMessageError, .connectivity)
        }
    }

    func test_send_deliversUnexpectedResponseErrorWhenStatusIsDifferentThan200() async {
        let textInput = "any message"
        let linesStream = anyValidLinesStream()
        let response = HTTPURLResponse(url: URL(string: "http://any-url.com")!, statusCode: 404, httpVersion: nil, headerFields: nil)!
        let (sut, _) = makeSUT(clientResult: .success((linesStream, response)))

        do {
            _ = try await sut.send(text: textInput)
            XCTFail("Expected error: \(SendMessageError.unexpectedResponse)")
        } catch {
            XCTAssertEqual(error as? SendMessageError, .unexpectedResponse)
        }
    }

    func test_send_deliversUnexpectedResponseErrorWhenLineDontStartWithData() async {
        let textInput = "any message"
        let anySuccessfulResponse = successfulHTTPURLResponse()
        let invalidLinesStream = linesStream(from: ["invalid line"])
        let (sut, _) = makeSUT(clientResult: .success((invalidLinesStream, anySuccessfulResponse)))

        guard let textStream = try? await sut.send(text: textInput) else {
            XCTFail("Expected to get the text stream")
            return
        }

        do {
            for try await _ in textStream {}
        } catch {
            XCTAssertEqual(error as? SendMessageError, .unexpectedResponse)
        }
    }

    func test_send_deliversTextOnSuccessfullyParsedText() async throws {
        let textInput = "any message"
        let expectedText = "Hello there!"
        let anySuccessfulResponse = successfulHTTPURLResponse()
        let validLinesStream = linesStream(from: validResponseLines())
        let (sut, _) = makeSUT(clientResult: .success((validLinesStream, anySuccessfulResponse)))

        let textStream = try await sut.send(text: textInput)

        var receivedText = ""
        for try await text in textStream {
            receivedText += text
        }

        XCTAssertEqual(receivedText, expectedText)
    }

    func test_send_deliversIncompleteResponseErrorWhenTerminationIsNotReceived() async throws {
        let textInput = "any message"
        let incompleteLinesStream = incompleteLinesStream()
        let anySuccessfulResponse = successfulHTTPURLResponse()
        let (sut, _) = makeSUT(clientResult: .success((incompleteLinesStream, anySuccessfulResponse)))

        let textStream = try await sut.send(text: textInput)

        do {
            for try await _ in textStream {}
            XCTFail("Expected error \(SendMessageError.incompleteResponse)")
        } catch {
            XCTAssertEqual(error as? SendMessageError, .incompleteResponse)
        }
    }
}

// MARK: Helpers

private func makeSUT(
    url: URL = URL(string: "http://any-url.com")!,
    apiKey: String = anySecretKey(),
    previousMessages: [Message] = [],
    clientResult: Result<(HTTPClient.LinesStream, URLResponse), Error> = .success((anyValidLinesStream(), successfulHTTPURLResponse()))
) -> (sut: MessageSender, client: HTTPClientSpy) {
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

private func successfulHTTPURLResponse() -> HTTPURLResponse {
    return HTTPURLResponse(url: URL(string: "http://any-url.com")!, statusCode: 200, httpVersion: nil, headerFields: nil)!
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
