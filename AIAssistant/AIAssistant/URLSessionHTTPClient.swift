//
//  URLSessionHTTPClient.swift
//  AIAssistant
//
//  Created by Patricio Sepúlveda Heise on 02-06-23.
//

import Foundation

public class URLSessionHTTPClient: HTTPClient {
    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func lines(from request: URLRequest) async throws -> (LinesStream, URLResponse) {
        guard let (bytesStream, response) = try? await session.bytes(for: request),
              let _ = response as? HTTPURLResponse else {
            throw HTTPClientError.connectivity
        }

        let linesStream = LinesStream { continuation in
            Task {
                for try await line in bytesStream.lines {
                    continuation.yield(with: .success(line))
                }
                continuation.finish()
            }
        }

        return (linesStream, response)
    }
}
