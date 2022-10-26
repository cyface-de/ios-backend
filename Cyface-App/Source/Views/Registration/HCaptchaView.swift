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
import HCaptcha

/**
An empty placeholder view, that is filled with the HCaptcha UI on a button press

 - author: Klemens Muthmann
 - version: 1.0.0
 */
struct UIViewWrapperView : UIViewRepresentable {
    var uiview = UIView()

    func makeUIView(context: Context) -> UIView {
        return uiview
    }

    func updateUIView(_ view: UIView, context: Context) {
    }
}

/**
The HCaptcha UI, used to verify that the registration is carried out by an actual human.

 - author: Klemens Muthmann
 - version: 1.0.0
 */
struct HCaptchaView: View {
    /// The view model used by this view from the HCaptcha framework.
    @StateObject var model = HCaptchaViewModel()
    /// The HCaptcha instance from the HCaptcha framework.
    private(set) var hcaptcha: HCaptcha!
    /// The placeholder view to fill with the HCaptcha UI.
    let placeholder = UIViewWrapperView()
    /// The application system settings
    let settings: Settings

    var body: some View {
        VStack{
            placeholder.frame(width: 400, height: 400, alignment: .center)
            Button(action: {
                    model.isLoading=true
                    hcaptcha.validate(on: placeholder.uiview) { result in
                        //DispatchQueue.main.async {
                            do {
                                model.token = try result.dematerialize()
                                model.isValidated = true
                                model.isLoading = false
                            } catch {
                                model.errorMessage = error.localizedDescription
                                model.isLoading = false
                            }
                        //}
                    }
                }
            ) {
                HStack {
                    ProgressView()
                        .opacity(model.isLoading ? 1.0: 0.0)
                    Text("I am human")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .padding([.trailing, .leading])
            .disabled(model.isLoading)

            NavigationLink(destination: RegistrationView(settings: settings, validationToken: model.token), isActive: $model.isValidated) {
                EmptyView()
            }
        }
        .tint(Color("Cyface-Green"))
        .alert("Error", isPresented: $model.showError, actions: {
            // actions
        }, message: {
            Text(model.errorMessage)
        })
        .tint(Color("Cyface-Green"))
    }

    /// Create a new instance of this view based on the provided application system settings.
    init(settings: Settings) {
        self.settings = settings
        guard let baseURL = URL(string: "http://localhost") else {
            fatalError()
        }

        hcaptcha = try! HCaptcha(apiKey: "e0055722-fb85-4130-832e-a5102c985da8", baseURL: baseURL)
        let hostView = self.placeholder.uiview
        hcaptcha.configureWebView { webview in
            webview.frame = hostView.bounds
        }
    }
}

struct HCaptchaView_Previews: PreviewProvider {
    
    static var previews: some View {
        HCaptchaView(settings: PreviewSettings())
    }
}
