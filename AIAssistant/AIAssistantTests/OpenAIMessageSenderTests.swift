//
//  OpenAIMessageSenderTests.swift
//  AIAssistantTests
//
//  Created by Patricio Sepúlveda Heise on 30-05-23.
//

import XCTest

protocol HTTPClient {
    func lines(for: URLRequest) throws -> LinesStream
}

typealias LinesStream = AsyncStream<String>

struct Message {
    let role: String
    let content: String
}

typealias SendMessageResult = Swift.Result<String, SendMessageError>

enum SendMessageError: Error {
    case exceededInputCharactersLimit
    case connectivity
    case readingResponse
}

class OpenAIMessageSender {
    private struct RequestBody: Encodable {
        let messages: [RequestMessage]
        let model: String
        let stream: Bool
    }

    private struct RequestMessage: Encodable {
        let content: String
        let role: String
    }

    private let client: HTTPClient
    private let url: URL
    private let apiKey: String
    private let defaultModel = "gpt-3.5-turbo"
    private let defaultStreamOption = true
    private let charactersLimit = 3000
    private let previousMessages: [Message]

    init(client: HTTPClient, url: URL, apiKey: String, previousMessages: [Message] = []) {
        self.client = client
        self.url = url
        self.apiKey = apiKey
        self.previousMessages = previousMessages
    }

    func send(text: String) async throws {
        guard isRespectingCharactersLimit(text: text) else {
            throw SendMessageError.exceededInputCharactersLimit
        }
        
        let urlRequest = urlRequest(text: text)
        
        guard let lines = try? client.lines(for: urlRequest) else {
            throw SendMessageError.connectivity
        }

        for await line in lines {
            if !line.hasPrefix("data: ") {
                throw SendMessageError.readingResponse
            }
        }
    }

    func isRespectingCharactersLimit(text: String) -> Bool {
        let previousMessagesCharactersCount = previousMessages
            .reduce(into: 0) { partialResult, message in
                partialResult += message.content.count
            }

        return previousMessagesCharactersCount + text.count <= charactersLimit
    }

    private func urlRequest(text: String) -> URLRequest {
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.allHTTPHeaderFields = [
            "Content-Type": "application/json",
            "Authorization": "Bearer \(apiKey)"
        ]

        let messages = previousMessages
            .appending(Message(role: "user", content: text))
            .map({ RequestMessage(content: $0.content, role: $0.role) })

        let requestBody = RequestBody(
            messages: messages,
            model: defaultModel,
            stream: defaultStreamOption
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys

        let encodedBody = try! encoder.encode(requestBody)

        urlRequest.httpBody = encodedBody

        return urlRequest
    }
}

extension Array {
    // Generates a copy of the Array including given element
    func appending(_ element: Element) -> Array {
        var newArray = self
        newArray.append(element)
        return newArray
    }
}

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

        try await sut.send(text: textInput)

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

        try await sut.send(text: textInput)

        XCTAssertEqual(client.sentRequests.first?.httpBody, expectedBody)
    }

    func test_send_deliversErrorOnInputExceedingCharacterLimit() async {
        let textInput = "Adding this text exceeds character limit"
        let threeThousandCharactersString = String(repeating: "a", count: 3000)
        let previousMessages: [Message] = [
            Message(role: "assistant", content: threeThousandCharactersString)
        ]
        let (sut, client) = makeSUT(previousMessages: previousMessages)

        do {
            _ = try await sut.send(text: textInput)
            XCTFail("Expected error: \(SendMessageError.exceededInputCharactersLimit)")
        } catch {
            XCTAssertEqual(error as? SendMessageError, .exceededInputCharactersLimit)
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

    func test_send_deliversReadingResponseErrorWhenLineDontStartWithData() async {
        let textInput = "any message"
        let (sut, _) = makeSUT(clientResult: .success(linesStream(from: ["invalid line"])))

        do {
            _ = try await sut.send(text: textInput)
            XCTFail("Expected error: \(SendMessageError.readingResponse)")
        } catch {
            XCTAssertEqual(error as? SendMessageError, .readingResponse)
        }
    }
}

// MARK: Helpers

private func makeSUT(
    url: URL = URL(string: "http://any-url.com")!,
    apiKey: String = anySecretKey(),
    previousMessages: [Message] = [],
    clientResult: Result<LinesStream, Error> = .success(anyValidLinesStream())
) -> (sut: OpenAIMessageSender, client: HTTPClientSpy) {
    let client = HTTPClientSpy(result: clientResult)
    let sut = OpenAIMessageSender(client: client, url: url, apiKey: apiKey, previousMessages: previousMessages)

    return (sut, client)
}

private func linesStream(from lines: [String]) -> LinesStream {
    return LinesStream { continuation in
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

private func anyValidLinesStream() -> LinesStream {
    return linesStream(from: validResponseLines())
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
        }
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
    let result: Result<LinesStream, Error>

    init(result: Result<LinesStream, Error>) {
        self.result = result
    }

    func lines(for urlRequest: URLRequest) throws -> LinesStream {
        sentRequests.append(urlRequest)
        return try result.get()
    }
}
