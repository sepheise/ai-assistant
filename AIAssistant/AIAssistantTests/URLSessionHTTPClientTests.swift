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

    func lines(from request: URLRequest) async throws -> LinesStream {
        guard let (_, response) = try? await session.bytes(for: request),
              let _ = response as? HTTPURLResponse else {
            throw HTTPClientError.connectivity
        }

        throw NSError(domain: "not yet implemented", code: 0)
    }
}

class URLSessionHTTPClientTests: XCTestCase {
    func test_lines_deliversErrorOnRequestError() async {
        URLProtocolStub.startInterceptingRequests()

        let urlRequest = URLRequest(url: URL(string: "http://any-url.com")!)
        let anyError = anyNSError()
        URLProtocolStub.stub(data: nil, response: nil, error: anyError)
        let sut = URLSessionHTTPClient()

        do {
            _ = try await sut.lines(from: urlRequest)
            XCTFail("Expected error: \(HTTPClientError.connectivity)")
        } catch {
            XCTAssertEqual(error as? HTTPClientError, .connectivity)
        }

        URLProtocolStub.stopInterceptingRequests()
    }

    func test_lines_deliversErrorOnAllInvalidCases() async {
        URLProtocolStub.startInterceptingRequests()
        await resultErrorFor(data: nil, response: nil, error: nil)
        await resultErrorFor(data: nil, response: nonHTTPURLResponse(), error: nil)
        await resultErrorFor(data: anyData(), response: nil, error: nil)
        await resultErrorFor(data: anyData(), response: nil, error: anyNSError())
        await resultErrorFor(data: nil, response: nonHTTPURLResponse(), error: anyNSError())
        await resultErrorFor(data: nil, response: anyHTTPURLResponse(), error: anyNSError())
        await resultErrorFor(data: anyData(), response: nonHTTPURLResponse(), error: anyNSError())
        await resultErrorFor(data: anyData(), response: anyHTTPURLResponse(), error: anyNSError())
        await resultErrorFor(data: anyData(), response: nonHTTPURLResponse(), error: nil)
        URLProtocolStub.stopInterceptingRequests()
    }
}

// MARK: - Helper methods

private func resultErrorFor(data: Data?, response: URLResponse?, error: Error?) async {
    URLProtocolStub.stub(data: data, response: response, error: error)
    let urlRequest = URLRequest(url: URL(string: "http://any-url.com")!)
    let sut = URLSessionHTTPClient()

    do {
        _ = try await sut.lines(from: urlRequest)
        XCTFail("Expected error: \(HTTPClientError.connectivity)")
    } catch {
        XCTAssertEqual(error as? HTTPClientError, .connectivity)
    }
}

private func anyURL() -> URL {
    return URL(string: "http://any-url.com")!
}

private func anyData() -> Data {
    return Data("any data".utf8)
}

private func anyNSError() -> NSError {
    return NSError(domain: "any error", code: 0)
}

private func anyHTTPURLResponse() -> HTTPURLResponse {
    return HTTPURLResponse(url: anyURL(), statusCode: 200, httpVersion: nil, headerFields: nil)!
}

private func nonHTTPURLResponse() -> URLResponse {
    return URLResponse(url: anyURL(), mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
}

private func successfulHTTPURLResponse() -> HTTPURLResponse {
    return HTTPURLResponse(url: anyURL(), statusCode: 200, httpVersion: nil, headerFields: nil)!
}

// MARK: - Test doubles

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
