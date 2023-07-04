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
            HStack {
                TextField("OpenAI API key", text: $viewModel.openAIApiKey)
                    .onAppear(perform: viewModel.onAppear)

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
            viewModel: SettingsViewModel(
                apiKeyLoader: inMemoryAPIKeyStore,
                apiKeySaver: inMemoryAPIKeyStore
            )
        )
    }
}
