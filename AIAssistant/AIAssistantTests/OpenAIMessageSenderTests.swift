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
    let client: HTTPClient
    let url: URL

    init(client: HTTPClient, url: URL) {
        self.client = client
        self.url = url
    }

    func send() {
        let urlRequest = URLRequest(url: url)
        client.lines(for: urlRequest)
    }
}

class OpenAIMessageSenderTests: XCTestCase {
    func test_init_doesNotSendAnyRequest() {
        let (_, client) = makeSUT()

        XCTAssertEqual(client.sentRequests, [])
    }

    func test_send_startRequestWithURL() {
        let url = URL(string: "http://any-url.com")!
        let (sut, client) = makeSUT(url: url)

        sut.send()

        XCTAssertEqual(client.sentRequests.count, 1)
        XCTAssertEqual(client.sentRequests.first?.url, url)
    }
}

// MARK: Helpers

private func makeSUT(url: URL = URL(string: "http://any-url.com")!) -> (sut: OpenAIMessageSender, client: HTTPClientSpy) {
    let client = HTTPClientSpy()
    let sut = OpenAIMessageSender(client: client, url: url)

    return (sut, client)
}

// MARK: Test Doubles

private class HTTPClientSpy: HTTPClient {
    var sentRequests = [URLRequest]()

    func lines(for urlRequest: URLRequest) {
        sentRequests.append(urlRequest)
    }
}
