//
//  SettingsViewModel.swift
//  AIAssistant
//
//  Created by Patricio Sepúlveda Heise on 03-07-23.
//

import Foundation

public class SettingsViewModel: ObservableObject {
    @Published public var openAIApiKey: String = ""
    @Published public var errorMessage: String
    public var canSave: Bool {
        !openAIApiKey.isEmpty
    }
    private let apiKeyLoader: APIKeyLoader
    private let apiKeySaver: APIKeySaver
    private let apiKeyDeleter: APIKeyDeleter

    public init(apiKeyLoader: APIKeyLoader, apiKeySaver: APIKeySaver, apiKeyDeleter: APIKeyDeleter, errorMessage: String = "") {
        self.apiKeyLoader = apiKeyLoader
        self.apiKeySaver = apiKeySaver
        self.apiKeyDeleter = apiKeyDeleter
        self.errorMessage = errorMessage
    }

    public func onAppear() async {
        do {
            let loaded = try await apiKeyLoader.load()

            await MainActor.run {
                openAIApiKey = loaded
            }
        } catch {
//            await MainActor.run {
//                errorMessage = "Couldn't load API Key"
//            }
            await setErrorMessage(message: "Couldn't load API Key", for: 2)
        }
    }

    public func saveAPIKey() async {
        guard !openAIApiKey.isEmpty else {
            return
        }

        do {
            try await apiKeySaver.save(openAIApiKey)
        } catch {
            await MainActor.run {
                errorMessage = "Couldn't save API Key"
            }
        }
    }

    public func deleteAPIKey() async {
        do {
            try await apiKeyDeleter.delete()

            await MainActor.run {
                openAIApiKey = ""
            }
        } catch {
            await MainActor.run {
                errorMessage = "Couldn't delete API Key"
            }
        }
    }

    @MainActor private func setErrorMessage(message: String, for seconds: TimeInterval) {
        self.errorMessage = message

        Timer.scheduledTimer(withTimeInterval: seconds, repeats: false) { [weak self] _ in
            guard let self else { return }

            self.errorMessage = ""
        }
    }
}
