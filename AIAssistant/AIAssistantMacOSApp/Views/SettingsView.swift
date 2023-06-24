//
//  SettingsView.swift
//  AIAssistantMacOSApp
//
//  Created by Patricio Sepúlveda Heise on 23-06-23.
//

import SwiftUI

struct SettingsView: View {
    @State var openAIApiKey: String = ""

    var body: some View {
        VStack {
            Text("Settings")
                .font(.title)
            Spacer()
            HStack {
                TextField("OpenAI API key", text: $openAIApiKey)
                Button(action: {}) {
                    Image(systemName: "trash.fill")
                        .accessibilityHint("Clears api key")
                }
            }
            Spacer()
        }
        .frame(height: 100)
        .padding(20)
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
