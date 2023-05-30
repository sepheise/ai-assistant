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

    let client: HTTPClient
    let url: URL
    let apiKey: String
    let defaultModel = "gpt-3.5-turbo"
    let defaultStreamOption = true

    init(client: HTTPClient, url: URL, apiKey: String) {
        self.client = client
        self.url = url
        self.apiKey = apiKey
    }

    func send(text: String) {
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.allHTTPHeaderFields = [
            "Content-Type": "application/json",
            "Authorization": "Bearer \(apiKey)"
        ]

        let requestBody = RequestBody(
            messages: [RequestMessage(content: text, role: "user")],
            model: defaultModel,
            stream: defaultStreamOption
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        urlRequest.httpBody = try! encoder.encode(requestBody)

        client.lines(for: urlRequest)
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

        sut.send(text: textInput)

        XCTAssertEqual(client.sentRequests.count, 1)
        XCTAssertEqual(client.sentRequests.first?.url, url)
        XCTAssertEqual(client.sentRequests.first?.httpMethod, "POST")
        XCTAssertEqual(client.sentRequests.first?.value(forHTTPHeaderField: "Content-Type"), "application/json")
        XCTAssertEqual(client.sentRequests.first?.value(forHTTPHeaderField: "Authorization"), "Bearer \(apiKey)")

        let expectedBodyJSON: [String: Any] = [
            "model": "gpt-3.5-turbo",
            "stream": true,
            "messages": [
                ["role": "user", "content": "\(textInput)"]
            ]
        ]
        let expectedHTTPBody = try! JSONSerialization.data(withJSONObject: expectedBodyJSON, options: [.sortedKeys])

        XCTAssertEqual(client.sentRequests.first?.httpBody, expectedHTTPBody)
    }
}

// MARK: Helpers

private func makeSUT(url: URL = URL(string: "http://any-url.com")!, apiKey: String = anySecretKey()) -> (sut: OpenAIMessageSender, client: HTTPClientSpy) {
    let client = HTTPClientSpy()
    let sut = OpenAIMessageSender(client: client, url: url, apiKey: apiKey)

    return (sut, client)
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
