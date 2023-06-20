//
//  PromptAndResponsesView.swift
//  AIAssistantMacOSApp
//
//  Created by Patricio Sepúlveda Heise on 20-06-23.
//

import SwiftUI
import AIAssistant

struct PromptsAndResponsesView: View {
    @Binding var promptResponses: [PromptResponse]

    var body: some View {
        ScrollView {
            ForEach(promptResponses) { promptResponse in
                Text(promptResponse.prompt)
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    .background(Color("UserInputBackground"))
                Text(promptResponse.response)
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
            }
        }
    }
}

struct PromptsAndResponsesView_Previews: PreviewProvider {
    static let previewPromptResponses = [
        PromptResponse(id: 0, prompt: "Question 1", response: "Some answer to question 1"),
        PromptResponse(id: 1, prompt: "Question 2", response: "Some answer to question 2"),
        PromptResponse(id: 2, prompt: "Question 3", response: "Some answer to question 3")
    ]

    static var previews: some View {
        PromptsAndResponsesView(promptResponses: .constant(previewPromptResponses))
    }
}
