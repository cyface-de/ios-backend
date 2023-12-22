/*
 * Copyright 2023 Cyface GmbH
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
 A dialog shown to the user to confirm account deletion.

 As this is a very destructive operation a confirmation is strictly required.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 - Since: 3.1.2
 */
struct DeleteAccountConfirmationDialog: View {
    /// The authenticator used to authorize the delete operation if approved.
    let authenticator: Authenticator
    /// The last error, that occurred; or `nil` if not.
    @Binding var error: Error?
    /// The current login status of the user. A user that has not been logged in cannot delete anything.
    @EnvironmentObject var loginStatus: LoginStatus

    var body: some View {
        VStack {
            Image(systemName: "exclamationmark.triangle")
                .imageScale(.large)
                .padding()
            Text("Achtung")
                .fontWeight(.bold)
            Text("Wenn Sie auf \"Wirklich Löschen\" klicken, wird ihr Zugang und alle ihre erfassten Daten unwiderbringlich gelöscht. Möchten Sie Ihr Nutzerprofil wirklich löschen?")
            HStack {
                Button(
                    action: {},
                    label: {
                        Spacer()
                        Text("Abbrechen")
                            .padding()
                        Spacer()
                    }
                )
                Button(action: {
                    Task {
                        do {
                            try await authenticator.delete()
                            try await (authenticator as! OAuthAuthenticator).logout()
                            loginStatus.isLoggedIn = false
                        } catch {
                            self.error = error
                        }
                    }
                }, label: {
                    Spacer()
                    Text("Wirklich Löschen")
                        .tint(.red)
                        .padding()
                    Spacer()
                })
            }
        }.padding()
    }
}

#if DEBUG
#Preview {
    DeleteAccountConfirmationDialog(authenticator: MockAuthenticator(), error: .constant(nil))
        .environmentObject(LoginStatus())
}
#endif
