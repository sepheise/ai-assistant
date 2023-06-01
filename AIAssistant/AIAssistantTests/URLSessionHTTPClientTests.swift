//
//  URLSessionHTTPClientTests.swift
//  AIAssistantTests
//
//  Created by Patricio Sepúlveda Heise on 31-05-23.
//

import XCTest
import AIAssistant

class URLSessionHTTPClient: HTTPClient {
    let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func lines(from request: URLRequest) async throws -> HTTPClient.LinesStream {
        do {
            _ = try await session.bytes(for: request)
        } catch {
            throw HTTPClientError.connectivity
        }

        throw NSError(domain: "not yet implemented", code: 0)
    }
}

class URLSessionHTTPClientTests: XCTestCase {
    func test_lines_deliversErrorOnRequestError() async {
        URLProtocolStub.startInterceptingRequests()

        let urlRequest = URLRequest(url: URL(string: "http://any-url.com")!)
        let sut = URLSessionHTTPClient()
        let anyError = NSError(domain: "any error", code: 0)
        URLProtocolStub.stub(data: nil, response: nil, error: anyError)

        do {
            _ = try await sut.lines(from: urlRequest)
            XCTFail("Expected error: \(HTTPClientError.connectivity)")
        } catch {
            XCTAssertEqual(error as? HTTPClientError, .connectivity)
        }

        URLProtocolStub.stopInterceptingRequests()
    }
}

class URLProtocolStub: URLProtocol {
    private static var stub: Stub?

    private struct Stub {
        let data: Data?
        let response: URLResponse?
        let error: Error?
    }

    static func startInterceptingRequests() {
        URLProtocol.registerClass(URLProtocolStub.self)
    }

    static func stopInterceptingRequests() {
        URLProtocol.unregisterClass(URLProtocolStub.self)
        stub = nil
    }

    static func stub(data: Data?, response: URLResponse?, error: Error?) {
        stub = Stub(data: data, response: response, error: error)
    }

    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override func startLoading() {
        if let response = URLProtocolStub.stub?.response {
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        }

        if let data = URLProtocolStub.stub?.data {
            client?.urlProtocol(self, didLoad: data)
        }

        if let error = URLProtocolStub.stub?.error {
            client?.urlProtocol(self, didFailWithError: error)
        }

        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
