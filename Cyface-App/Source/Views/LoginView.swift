//
//  ContentView.swift
//  Cyface-App
//
//  Created by Klemens Muthmann on 25.03.22.
//

import SwiftUI

struct LoginView: View {

    @State var credentials: Credentials
    @State var loginSuccessful = false

    var body: some View {
        NavigationView {
            VStack {
                NavigationLink(destination: MeasurementView(), isActive: $loginSuccessful) {
                    EmptyView()
                }

                Image("Cyface-Logo")


                VStack {
                    CyfaceTextField(label: "Username", binding: $credentials.username)
                    CyfaceTextField(label: "Password", binding: $credentials.password)
                }.padding()


                    Button("Login") {
                        credentials.login(onSuccess: {
                            loginSuccessful = true
                        }, onFailure: {_ in})
                    }
                    .buttonStyle(CyfaceButton())
                    .frame(maxWidth: .infinity)


                Text("or").padding()

                Button("Register New Account") {

                }
                .buttonStyle(CyfaceButton())
                .frame(maxWidth: .infinity)
            }.navigationBarHidden(true)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let credentials = Credentials(username: "", password: "")

        LoginView(credentials: credentials).preferredColorScheme(.light)
        LoginView(credentials: credentials).preferredColorScheme(.dark)
    }
}
