//
//  OpenAIMessageSenderTests.swift
//  AIAssistantTests
//
//  Created by Patricio Sepúlveda Heise on 30-05-23.
//

import XCTest

protocol HTTPClient {
    func lines(for: URLRequest)
}

struct Message {
    let role: String
    let content: String
}

typealias SendMessageResult = Swift.Result<String, SendMessageError>

enum SendMessageError: Error {
    case exceededInputCharactersLimit
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

    func send(text: String, completion: @escaping (SendMessageResult) -> Void) {
        guard isRespectingCharactersLimit(text: text) else {
            completion(.failure(.exceededInputCharactersLimit))
            return
        }

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
        urlRequest.httpBody = try! encoder.encode(requestBody)

        client.lines(for: urlRequest)
    }

    func isRespectingCharactersLimit(text: String) -> Bool {
        let previousMessagesCharactersCount = previousMessages
            .reduce(into: 0) { partialResult, message in
                partialResult += message.content.count
            }

        return previousMessagesCharactersCount + text.count <= charactersLimit
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

    func test_send_startRequestWithAllNecessaryParametersDefaultOptionsAndTextInput() {
        let url = URL(string: "http://any-url.com")!
        let apiKey = anySecretKey()
        let textInput = "any message"
        let (sut, client) = makeSUT(url: url, apiKey: apiKey)

        sut.send(text: textInput) { _ in }

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

    func test_send_includePreviousMessages() {
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

        sut.send(text: textInput) { _ in }

        XCTAssertEqual(client.sentRequests.first?.httpBody, expectedBody)
    }

    func test_send_deliversErrorOnInputExceedingCharacterLimit() {
        let textInput = "Adding this text exceeds character limit"
        let threeThousandCharactersString = String(repeating: "a", count: 3000)
        let previousMessages: [Message] = [
            Message(role: "assistant", content: threeThousandCharactersString)
        ]
        let (sut, client) = makeSUT(previousMessages: previousMessages)

        let exp = expectation(description: "Wait for send message completion")

        var receivedResult: SendMessageResult?
        sut.send(text: textInput) { result in
            receivedResult = result
            exp.fulfill()
        }

        wait(for: [exp], timeout: 1.0)

        XCTAssertEqual(receivedResult, .failure(.exceededInputCharactersLimit))
        XCTAssertEqual(client.sentRequests.count, 0)
    }
}

// MARK: Helpers

private func makeSUT(url: URL = URL(string: "http://any-url.com")!, apiKey: String = anySecretKey(), previousMessages: [Message] = []) -> (sut: OpenAIMessageSender, client: HTTPClientSpy) {
    let client = HTTPClientSpy()
    let sut = OpenAIMessageSender(client: client, url: url, apiKey: apiKey, previousMessages: previousMessages)

    return (sut, client)
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

// MARK: Test Doubles

private class HTTPClientSpy: HTTPClient {
    var sentRequests = [URLRequest]()

    func lines(for urlRequest: URLRequest) {
        sentRequests.append(urlRequest)
    }
}
