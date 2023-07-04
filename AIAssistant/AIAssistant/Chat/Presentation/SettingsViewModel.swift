//
//  SettingsViewModel.swift
//  AIAssistant
//
//  Created by Patricio Sepúlveda Heise on 03-07-23.
//

import Foundation

public class SettingsViewModel: ObservableObject {
    @Published public var openAIApiKey: String = ""
    @Published public var errorMessage: String = ""
    public var canSave: Bool {
        !openAIApiKey.isEmpty
    }
    private let apiKeyLoader: APIKeyLoader
    private let apiKeySaver: APIKeySaver

    public init(apiKeyLoader: APIKeyLoader, apiKeySaver: APIKeySaver) {
        self.apiKeyLoader = apiKeyLoader
        self.apiKeySaver = apiKeySaver
    }

    public func onAppear() {
        do {
            openAIApiKey = try apiKeyLoader.load()
        } catch {
            errorMessage = "Couldn't load API Key"
        }
    }

    public func saveAPIKey() {
        guard !openAIApiKey.isEmpty else {
            return
        }

        do {
            try apiKeySaver.save(openAIApiKey)
        } catch {
            errorMessage = "Couldn't save API Key"
        }
    }
}
