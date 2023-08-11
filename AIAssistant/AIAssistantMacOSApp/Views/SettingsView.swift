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
        ZStack(alignment: .top) {
            if !viewModel.errorMessage.isEmpty {
                ErrorView(errorMessage: viewModel.errorMessage)
            }
            VStack {
                HStack(alignment: .center, spacing: 10) {
                    Text("OpenAI API Key")

                    TextField("OpenAI API key", text: $viewModel.openAIApiKey)
                        .submitLabel(.done)
                        .textFieldStyle(.roundedBorder)
                        .onAppear {
                            Task {
                                await viewModel.onAppear()
                            }
                        }

                    Button(
                        action: {
                            Task {
                                await viewModel.saveAPIKey()
                            }
                        },
                        label: {
                            Image(systemName: "checkmark")
                                .accessibilityHint("Save")
                        }
                    )
                    .disabled(!viewModel.canSave)

                    Button(
                        action: {
                            Task {
                                await viewModel.deleteAPIKey()
                            }
                        },
                        label: {
                            Image(systemName: "trash.fill")
                                .accessibilityHint("Clears api key")
                        })
                }
                .padding(10)
                Spacer()
            }
            .frame(alignment: .top)
            .padding(20)
        }
    }
}

#if DEBUG
struct SettingsView_Previews: PreviewProvider {
    private static let inMemoryAPIKeyStore = InMemoryAPIKeyStore(apiKey: "test key")

    private static let viewModel = SettingsViewModel(
        apiKeyLoader: inMemoryAPIKeyStore,
        apiKeySaver: inMemoryAPIKeyStore,
        apiKeyDeleter: inMemoryAPIKeyStore
    )

    private static let viewModelWithError = SettingsViewModel(
        apiKeyLoader: inMemoryAPIKeyStore,
        apiKeySaver: inMemoryAPIKeyStore,
        apiKeyDeleter: inMemoryAPIKeyStore,
        errorMessage: "Settings error"
    )

    static var previews: some View {
        SettingsView(viewModel: viewModel)

        SettingsView(viewModel: viewModelWithError)
            .previewDisplayName("Settings View with Error")
    }
}
#endif
