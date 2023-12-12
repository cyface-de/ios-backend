//
//  DeleteAccountConfirmationDialog.swift
//  RFR
//
//  Created by Klemens Muthmann on 08.12.23.
//

import SwiftUI
import DataCapturing

struct DeleteAccountConfirmationDialog: View {

    let authenticator: Authenticator
    @Binding var error: Error?
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

#Preview {
    DeleteAccountConfirmationDialog(authenticator: MockAuthenticator(), error: .constant(nil))
        .environmentObject(LoginStatus())
}
