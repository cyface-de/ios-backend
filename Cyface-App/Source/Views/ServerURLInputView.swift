//
//  ServerURLInputView.swift
//  Cyface-App
//
//  Created by Klemens Muthmann on 20.06.22.
//

import SwiftUI

struct ServerURLInputView: View {

    @State private var textInput: String = ""
    @EnvironmentObject var appState: ApplicationState

    init(initialURL: String) {
        self._textInput = State(wrappedValue: initialURL)
    }

    var body: some View {
        VStack {
            TextField("Please enter a valid Cyface server URL!", text: $textInput)
            HStack {
                Button("Clear") {
                    textInput = ""
                }
                Button("OK") {
                    appState.settings.serverUrl = textInput
                }
            }
        }
    }
}

struct ServerURLInputView_Previews: PreviewProvider {
    static var previews: some View {
        ServerURLInputView(initialURL: "hhtp://localhost:8080/api/v3/").environmentObject(ApplicationState(settings: PreviewSettings()))
    }
}
