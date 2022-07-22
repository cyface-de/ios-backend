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
            HStack {
                Image(systemName: "cloud")
            TextField("Please enter a valid Cyface server URL!", text: $textInput)
            }
            .padding()
            .overlay(
                    RoundedRectangle(cornerRadius: 15)
            .stroke(lineWidth: 2))
            .foregroundColor(.gray)
            .padding()


            Spacer()

            HStack {
                Button( action: {
                    textInput = ""
                }) {
                    Text("Clear")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Button(action: {
                    appState.settings.serverUrl = textInput
                }) {
                    Text("OK")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .navigationTitle("Server Address")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .tint(Color("Cyface-Green"))
    }
}

struct ServerURLInputView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ServerURLInputView(initialURL: "http://localhost:8080/api/v3/").environmentObject(ApplicationState(settings: PreviewSettings()))
        }
    }
}
