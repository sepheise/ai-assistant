//
//  OpenAIMessageSender.swift
//  AIAssistant
//
//  Created by Patricio Sepúlveda Heise on 31-05-23.
//

import Foundation

public class OpenAIPromptSender: PromptSender {
    private struct RequestBody: Encodable {
        let messages: [RequestMessage]
        let model: String
        let stream: Bool
    }

    private struct RequestMessage: Encodable {
        let content: String
        let role: String
    }

    private struct StreamCompletionResponse: Decodable {
        let choices: [StreamChoice]
    }

    private struct StreamChoice: Decodable {
        let finishReason: String?
        let delta: StreamMessage
    }

    private struct StreamMessage: Decodable {
        let role: String?
        let content: String?
    }

    private let client: HTTPClient
    private let url: URL
    private let apiKey: String
    private let defaultModel = "gpt-3.5-turbo"
    private let defaultStreamOption = true
    private let charactersLimit = 3000

    public init(client: HTTPClient, url: URL, apiKey: String) {
        self.client = client
        self.url = url
        self.apiKey = apiKey
    }

    public func send(prompt: String, previousMessages: [Message] = []) async throws -> PromptResponseStream {
        guard isRespectingCharactersLimit(text: prompt, previousMessages: previousMessages) else {
            throw SendPromptError.invalidInput
        }

        let urlRequest = urlRequest(text: prompt, previousMessages: previousMessages)

        guard let (lines, response) = try? await client.lines(from: urlRequest) else {
            throw SendPromptError.connectivity
        }

        guard let resp = response as? HTTPURLResponse,
              resp.statusCode == 200 else {
            throw SendPromptError.unexpectedResponse
        }

        return PromptResponseStream { continuation in
            Task {
                var lastLine: String?

                for await line in lines {
                    guard line.hasPrefix("data: "),
                          let lineData = line.dropFirst(6).data(using: .utf8) else {
                        continuation.yield(with: .failure(SendPromptError.unexpectedResponse))
                        return
                    }

                    if let decoded = try? JSONDecoder().decode(StreamCompletionResponse.self, from: lineData),
                       let content = decoded.choices.first?.delta.content {
                        continuation.yield(with: .success(content))
                    }

                    lastLine = line
                }

                if let lastLine = lastLine,
                   lastLine == "data: [DONE]" {
                    continuation.finish()
                } else {
                    continuation.finish(throwing: SendPromptError.incompleteResponse)
                }

            }
        }
    }

    private func isRespectingCharactersLimit(text: String, previousMessages: [Message]) -> Bool {
        let previousMessagesCharactersCount = previousMessages
            .reduce(into: 0) { partialResult, message in
                partialResult += message.content.count
            }

        return previousMessagesCharactersCount + text.count <= charactersLimit
    }

    private func urlRequest(text: String, previousMessages: [Message]) -> URLRequest {
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.allHTTPHeaderFields = [
            "Content-Type": "application/json",
            "Authorization": "Bearer \(apiKey)"
        ]

        let messages = previousMessages
            .appending(Message(role: .user, content: text))
            .map({ RequestMessage(content: $0.content, role: $0.role.description) })

        let requestBody = RequestBody(
            messages: messages,
            model: defaultModel,
            stream: defaultStreamOption
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys

        let encodedBody = try! encoder.encode(requestBody)

        urlRequest.httpBody = encodedBody

        return urlRequest
    }
}

private extension Array {
    // Generates a copy of the Array including given element
    func appending(_ element: Element) -> Array {
        var newArray = self
        newArray.append(element)
        return newArray
    }
}