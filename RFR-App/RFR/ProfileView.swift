/*
 * Copyright 2023-2024 Cyface GmbH
 *
 * This file is part of the Ready for Robots iOS App.
 *
 * The Ready for Robots iOS App is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * The Ready for Robots iOS App is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with the Ready for Robots iOS App. If not, see <http://www.gnu.org/licenses/>.
 */
import SwiftUI
import DataCapturing

/**
 View showing information and functions to manage the users profile.
 This currently encompasses only deleting the user.

 - Author: Klemens Muthmann
 - Version: 1.0.1
 - Since: 3.1.2
 */
struct ProfileView: View {
    /// The authenticator to use for authorizing the delete request.
    let authenticator: Authenticator
    /// The last error if any or `nil` otherwise.
    @State var error: Error?
    /// A flag becomming `true` if the delete button was pressed, showing a confirmation dialog in that case.
    @State var deleteButtonPressed: Bool = false

    var body: some View {
        if let error = error {
            ErrorView(error: error)
        } else {
            List {
                Button(action: {
                    deleteButtonPressed.toggle()
                }, label: {
                    Text("Nutzerprofil und alle zugehörigen Daten löschen.")
                })
                .tint(.red)
                .sheet(isPresented: $deleteButtonPressed, content: {
                    DeleteAccountConfirmationDialog(
                        authenticator: authenticator,
                        error: $error
                    )
                })
            }
        }
    }
}

#if DEBUG
#Preview {
    ProfileView(authenticator: MockAuthenticator())
}

#Preview {
    ProfileView(authenticator: MockAuthenticator(), deleteButtonPressed: true)
}

#Preview {
    ProfileView(authenticator: MockAuthenticator(), error: AuthenticationError.unableToAuthenticate)
}
#endif
