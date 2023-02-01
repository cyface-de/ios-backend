//
//  LoginView.swift
//  RFR
//
//  Created by Klemens Muthmann on 27.01.23.
//

import SwiftUI

struct LoginView: View {
    // TODO: Move to Viewmodel
    @State private var username: String = ""
    // TODO: Move to Viewmodel
    @State private var password: String = ""

    var body: some View {
        NavigationStack {
            VStack {

                Image("RFR-Logo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding()

                VStack {
                    HStack {
                        Image(systemName: "person")
                        TextField("Username", text: $username)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                    }
                    .padding()
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(lineWidth: 2))
                    .foregroundColor(.gray)

                    HStack {
                        Image(systemName: "lock")
                        SecureField("Password", text: $password)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                    }
                    .padding()
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(lineWidth: 2)
                    )
                    .foregroundColor(.gray)

                }.padding()


                /*AsyncButton(action: {
                 do {
                 try credentials.login(onSuccess: {
                 appState.isLoggedIn = true
                 }, onFailure: { error in
                 showError = true
                 errorMessage = error.localizedDescription
                 })
                 } catch {
                 showError = true
                 errorMessage = error.localizedDescription
                 }
                 }) {
                 Text("Login")
                 .frame(maxWidth: .infinity)
                 }*/
                NavigationLink(destination: LiveView(viewModel: viewModelExample)) {
                    Text("Login")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .padding([.trailing, .leading])

                LabelledDivider(label: "or")

                NavigationLink(destination: RegistrationView()) {
                    Text("Register New Account")
                }
                .frame(maxWidth: .infinity)
            }
            .navigationTitle("Anmeldung")
        }

        /*.alert("Error", isPresented: $showError, actions: {
            // actions
        }, message: {
            Text(errorMessage ?? "")
        })*/
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
