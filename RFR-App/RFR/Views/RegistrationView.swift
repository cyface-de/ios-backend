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
 View shown to allow the user to register with the Cyface server.

 - author: Klemens Muthmann
 - version: 1.0.0
 */
struct RegistrationView: View {
    /// The view model containing the registration information.
    @StateObject var model: RegistrationViewModel
    @Binding var showRegistrationView: Bool

    var body: some View {
        VStack {
            HStack {
                Button(action: {
                    showRegistrationView = false
                }) {
                    HStack {
                        Image(systemName: "chevron.backward")
                            .font(.title)
                        Text("Zurück")
                            .font(.title2)
                    }
                }
                Spacer()
            }
            if let error = model.error {
                ErrorView(error: error)
            } else if model.isValidated {
                RegistrationDetailsView(
                    model: model,
                    showRegistrationView: $showRegistrationView
                )
            } else {
                HCaptchaView(
                    model: model
                )
            }
        }
    }
}

#if DEBUG
struct RegistrationViewContainer_Previews: PreviewProvider {
    @State static var showRegistrationView = true
    static var previews: some View {
        NavigationView {
            RegistrationView(
                model: RegistrationViewModel(),
                showRegistrationView: $showRegistrationView
            )
        }

        NavigationView {
            RegistrationView(
                model: RegistrationViewModel(),
                showRegistrationView: $showRegistrationView
            )
        }.preferredColorScheme(.dark)
    }
}
#endif
