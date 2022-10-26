/*
 * Copyright 2022 Cyface GmbH
 *
 * This file is part of the Cyface SDK for iOS.
 *
 * The Cyface SDK for iOS is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * The Cyface SDK for iOS is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with the Cyface SDK for iOS. If not, see <http://www.gnu.org/licenses/>.
 */

import SwiftUI

/**
 View providing an input field to enter a valid server URL.

 This view is shown if the URL provided via the system settings is not valid. It prevents the user from starting the application with an invalid URL.

 - author: Klemens Muthmann
 - version: 1.0.0
 */
struct ServerURLInputView: View {
    /// The URL entered by the user.
    @State private var textInput: String = ""
    /// The current state of the application.
    @EnvironmentObject var appState: ApplicationState

    /// Create a new version of this view provided with an initial URL to edit.
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
