//
//  OpenAIMessageSenderTests.swift
//  AIAssistantTests
//
//  Created by Patricio Sepúlveda Heise on 30-05-23.
//

import XCTest

protocol HTTPClient {}

class OpenAIMessageSender {
    let client: HTTPClient

    init(client: HTTPClient) {
        self.client = client
    }
}

class OpenAIMessageSenderTests: XCTestCase {
    func test_init_doesNotSendAnyRequest() {
        let client = HTTPClientSpy()
        let _ = OpenAIMessageSender(client: client)

        XCTAssertEqual(client.sentRequests, 0)
    }

}

// MARK: Test Doubles

private class HTTPClientSpy: HTTPClient {
    var sentRequests: Int = 0
}
