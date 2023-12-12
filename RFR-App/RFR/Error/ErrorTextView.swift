//
//  ErrorTextView.swift
//  RFR
//
//  Created by Klemens Muthmann on 04.12.23.
//

import SwiftUI

struct ErrorTextView: View {
    let errorMessage: String

    var body: some View {
        VStack {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                Text("Fehler")
                    .font(.largeTitle)
            }
            ScrollView {
                Text(errorMessage)
                    .textSelection(.enabled)
            }
        }
        .padding()
    }
}

#Preview {
    ErrorTextView(errorMessage: "Test Error")
}
