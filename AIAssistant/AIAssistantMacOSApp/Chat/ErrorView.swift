//
//  ErrorView.swift
//  AIAssistantMacOSApp
//
//  Created by Patricio Sepúlveda Heise on 14-07-23.
//

import SwiftUI

struct ErrorView: View {
    let errorMessage: String

    var body: some View {
        HStack(alignment: .top) {
            Text(errorMessage)
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .font(.caption)
                .multilineTextAlignment(.leading)
                .padding(10)
                .foregroundColor(.black)
        }
        .background(.yellow)
    }
}

struct ErrorView_Previews: PreviewProvider {
    static var previews: some View {
        ErrorView(errorMessage: "Some error")
    }
}
