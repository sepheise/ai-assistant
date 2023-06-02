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
        guard let (bytesStream, response) = try? await session.bytes(for: request),
              let _ = response as? HTTPURLResponse else {
            throw HTTPClientError.connectivity
        }

        return LinesStream { continuation in
            Task {
                for try await line in bytesStream.lines {
                    continuation.yield(with: .success(line))
                }
                continuation.finish()
            }
        }
    }
}

class URLSessionHTTPClientTests: XCTestCase {
    override class func setUp() {
        super.setUp()
        URLProtocolStub.startInterceptingRequests()
    }

    override class func tearDown() {
        super.tearDown()
        URLProtocolStub.stopInterceptingRequests()
    }

    func test_lines_deliversErrorOnRequestError() async {
        let urlRequest = URLRequest(url: anyURL())
        let anyError = anyNSError()
        URLProtocolStub.stub(data: nil, response: nil, error: anyError)
        let sut = URLSessionHTTPClient()

        do {
            _ = try await sut.lines(from: urlRequest)
            XCTFail("Expected error: \(HTTPClientError.connectivity)")
        } catch {
            XCTAssertEqual(error as? HTTPClientError, .connectivity)
        }
    }

    func test_lines_deliversErrorOnAllInvalidCases() async {
        await resultErrorFor(data: nil, response: nil, error: nil)
        await resultErrorFor(data: nil, response: nonHTTPURLResponse(), error: nil)
        await resultErrorFor(data: anyData(), response: nil, error: nil)
        await resultErrorFor(data: anyData(), response: nil, error: anyNSError())
        await resultErrorFor(data: nil, response: nonHTTPURLResponse(), error: anyNSError())
        await resultErrorFor(data: nil, response: anyHTTPURLResponse(), error: anyNSError())
        await resultErrorFor(data: anyData(), response: nonHTTPURLResponse(), error: anyNSError())
        await resultErrorFor(data: anyData(), response: anyHTTPURLResponse(), error: anyNSError())
        await resultErrorFor(data: anyData(), response: nonHTTPURLResponse(), error: nil)
    }

    func test_lines_deliversEmptyLinesOnNilData() async throws {
        let urlRequest = URLRequest(url: anyURL())
        let succesfulResponse = successfulHTTPURLResponse()
        URLProtocolStub.stub(data: nil, response: succesfulResponse, error: nil)
        let sut = URLSessionHTTPClient()

        let linesStream = try await sut.lines(from: urlRequest)

        var receivedLines = [String]()
        for try await line in linesStream {
            receivedLines.append(line)
        }

        XCTAssertEqual(receivedLines, [])
    }

    func test_lines_deliversEmptyLinesOnEmptyData() async throws {
        let urlRequest = URLRequest(url: anyURL())
        let succesfulResponse = successfulHTTPURLResponse()
        URLProtocolStub.stub(data: Data("".utf8), response: succesfulResponse, error: nil)
        let sut = URLSessionHTTPClient()

        let linesStream = try await sut.lines(from: urlRequest)

        var receivedLines = [String]()
        for try await line in linesStream {
            receivedLines.append(line)
        }

        XCTAssertEqual(receivedLines, [])
    }

    func test_lines_deliversLinesOnSuccessfulResponse() async throws {
        let urlRequest = URLRequest(url: anyURL())
        let validData = Data(validResponseString().utf8)
        let succesfulResponse = successfulHTTPURLResponse()
        URLProtocolStub.stub(data: validData, response: succesfulResponse, error: nil)
        let sut = URLSessionHTTPClient()

        let linesStream = try await sut.lines(from: urlRequest)

        let expectedLines: [String] = [
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
            data: [DONE]
            """
        ]

        var receivedLines = [String]()
        for try await line in linesStream {
            receivedLines.append(line)
        }

        XCTAssertEqual(receivedLines.count, 5)
        XCTAssertEqual(receivedLines, expectedLines)
    }
}

// MARK: - Helper methods

private func resultErrorFor(data: Data?, response: URLResponse?, error: Error?) async {
    URLProtocolStub.stub(data: data, response: response, error: error)
    let urlRequest = URLRequest(url: anyURL())
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

// MARK: - Stub data

private func validResponseString() -> String {
    return """
        data: {"id":"chatcmpl-7Jgsv2kvsTBdl1KYYooO17tDRLvKm","object":"chat.completion.chunk","created":1684927437,"model":"gpt-3.5-turbo-0301","choices":[{"delta":{"role":"assistant"},"index":0,"finish_reason":null}]}

        data: {"id":"chatcmpl-7Jgsv2kvsTBdl1KYYooO17tDRLvKm","object":"chat.completion.chunk","created":1684927437,"model":"gpt-3.5-turbo-0301","choices":[{"delta":{"content":"Hello"},"index":0,"finish_reason":null}]}

        data: {"id":"chatcmpl-7Jgsv2kvsTBdl1KYYooO17tDRLvKm","object":"chat.completion.chunk","created":1684927437,"model":"gpt-3.5-turbo-0301","choices":[{"delta":{"content":" there"},"index":0,"finish_reason":null}]}

        data: {"id":"chatcmpl-7Jgsv2kvsTBdl1KYYooO17tDRLvKm","object":"chat.completion.chunk","created":1684927437,"model":"gpt-3.5-turbo-0301","choices":[{"delta":{"content":"!"},"index":0,"finish_reason":null}]}

        data: [DONE]


        """
}
