//
//  HTTPClient.swift
//  AIAssistant
//
//  Created by Patricio Sepúlveda Heise on 31-05-23.
//

import Foundation

public protocol HTTPClient {
    func lines(for: URLRequest) throws -> LinesStream
}

public typealias LinesStream = AsyncStream<String>
