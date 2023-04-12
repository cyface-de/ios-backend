//
//  ErrorView.swift
//  RFR
//
//  Created by Klemens Muthmann on 12.04.23.
//

import SwiftUI

struct ErrorView: View {
    let error: Error

    var body: some View {
        VStack {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                Text("Fehler")
                    .font(.largeTitle)
            }
            ScrollView {
                Text(error.localizedDescription)
                    .textSelection(.enabled)
            }
        }
        .padding()
    }
}

struct ErrorView_Previews: PreviewProvider {
    static var previews: some View {
        ErrorView(error: RFRError.missingAuthenticator)
    }
}
