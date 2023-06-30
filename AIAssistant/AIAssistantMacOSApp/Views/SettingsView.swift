//
//  SettingsView.swift
//  AIAssistantMacOSApp
//
//  Created by Patricio Sepúlveda Heise on 23-06-23.
//

import SwiftUI
import AIAssistant

struct SettingsView: View {
    @State var openAIApiKey: String = ""
    @State var errorMessage: String = ""

    private let apiKeyLoader: APIKeyLoader
    private let apiKeySaver: APIKeySaver

    init(apiKeyLoader: APIKeyLoader, apiKeySaver: APIKeySaver) {
        self.apiKeyLoader = apiKeyLoader
        self.apiKeySaver = apiKeySaver
    }

    func saveAPIKey() {
        do {
            try apiKeySaver.save(openAIApiKey)
        } catch {
            errorMessage = "Couldn't save API Key"
        }
    }

    func onAppear() {
        do {
            openAIApiKey = try apiKeyLoader.load()
        } catch {
            errorMessage = "Couldn't load API Key"
        }
    }

    var body: some View {
        VStack {
            HStack {
                TextField("OpenAI API key", text: $openAIApiKey)
                    .onAppear(perform: onAppear)

                Button(
                    action: {
                        saveAPIKey()
                    },
                    label: {
                        Image(systemName: "checkmark")
                            .accessibilityHint("Save")
                    }
                )
                .disabled(openAIApiKey.isEmpty)

                Button(action: {}) {
                    Image(systemName: "trash.fill")
                        .accessibilityHint("Clears api key")
                }
            }
            Spacer()
        }
        .frame(alignment: .top)
        .padding(20)
    }
}

struct SettingsView_Previews: PreviewProvider {
    private static let inMemoryAPIKeyStore = InMemoryAPIKeyStore()

    static var previews: some View {
        SettingsView(
            apiKeyLoader: inMemoryAPIKeyStore,
            apiKeySaver: inMemoryAPIKeyStore
        )
    }
}
