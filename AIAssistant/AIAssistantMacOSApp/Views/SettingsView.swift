//
//  SettingsView.swift
//  AIAssistantMacOSApp
//
//  Created by Patricio Sepúlveda Heise on 23-06-23.
//

import SwiftUI
import AIAssistant

struct SettingsView: View {
    @ObservedObject private var viewModel: SettingsViewModel

    init(viewModel: SettingsViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack {
            HStack(alignment: .center, spacing: 10) {
                Text("OpenAI API Key")

                TextField("OpenAI API key", text: $viewModel.openAIApiKey)
                    .submitLabel(.done)
                    .onAppear(perform: viewModel.onAppear)
                    .textFieldStyle(.roundedBorder)

                Button(
                    action: {
                        viewModel.saveAPIKey()
                    },
                    label: {
                        Image(systemName: "checkmark")
                            .accessibilityHint("Save")
                    }
                )
                .disabled(!viewModel.canSave)

                Button(action: {}) {
                    Image(systemName: "trash.fill")
                        .accessibilityHint("Clears api key")
                }
            }
            .padding(10)
            Spacer()
        }
        .frame(alignment: .top)
        .padding(20)
    }
}

struct SettingsView_Previews: PreviewProvider {
    private static let inMemoryAPIKeyStore = InMemoryAPIKeyStore(apiKey: "test key")

    static var previews: some View {
        SettingsView(
            viewModel: SettingsViewModel(
                apiKeyLoader: inMemoryAPIKeyStore,
                apiKeySaver: inMemoryAPIKeyStore
            )
        )
    }
}
