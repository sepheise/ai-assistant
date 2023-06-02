//
//  HTTPClient.swift
//  AIAssistant
//
//  Created by Patricio Sepúlveda Heise on 31-05-23.
//

import Foundation

public protocol HTTPClient {
    typealias LinesStream = AsyncStream<String>

    func lines(from: URLRequest) async throws -> (LinesStream, URLResponse)
}

public enum HTTPClientError: Error {
    case connectivity
}
