//
//  OpenAIMessageSenderTests.swift
//  AIAssistantTests
//
//  Created by Patricio Sepúlveda Heise on 30-05-23.
//

import XCTest

protocol HTTPClient {
    func lines()
}

class OpenAIMessageSender {
    let client: HTTPClient

    init(client: HTTPClient) {
        self.client = client
    }

    func send() {
        client.lines()
    }
}

class OpenAIMessageSenderTests: XCTestCase {
    func test_init_doesNotSendAnyRequest() {
        let client = HTTPClientSpy()
        let _ = OpenAIMessageSender(client: client)

        XCTAssertEqual(client.sentRequests, 0)
    }

    func test_send_startRequest() {
        let client = HTTPClientSpy()
        let sut = OpenAIMessageSender(client: client)

        sut.send()

        XCTAssertEqual(client.sentRequests, 1)
    }
}

// MARK: Test Doubles

private class HTTPClientSpy: HTTPClient {
    var sentRequests: Int = 0

    func lines() {
        sentRequests += 1
    }
}
