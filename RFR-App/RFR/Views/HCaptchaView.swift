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
struct UIViewWrapperView: UIViewRepresentable {
    var uiview = UIView()

    func makeUIView(context: Context) -> UIView {
        uiview.backgroundColor = .gray
        return uiview
    }

    func updateUIView(_ view: UIView, context: Context) {
        // nothing to update
    }
}

// Example of hCaptcha usage
struct HCaptchaView: View {
    @ObservedObject var model: RegistrationViewModel

    private(set) var hcaptcha: HCaptcha!

    let placeholder = UIViewWrapperView()

    var body: some View {
        VStack{
            placeholder.frame(width: 640, height: 640, alignment: .center)
            Button(action: {
                    //model.isLoading=true
                    hcaptcha.validate(on: placeholder.uiview) { result in
                            do {
                                model.token = try result.dematerialize()
                                model.isValidated = true
                                model.isLoading = false
                            } catch {
                                model.error = error
                                model.isLoading = false
                            }
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
            .foregroundColor(Color("ButtonText"))
        }
    }

    func showCaptcha(_ view: UIView) {
        hcaptcha.validate(on: view) { result in
            print(result)
        }
    }


    init(model: RegistrationViewModel) {
        self.model = model
        hcaptcha = try? HCaptcha(apiKey: "e0055722-fb85-4130-832e-a5102c985da8", baseURL: URL(string: "http://localhost")!)
        let hostView = self.placeholder.uiview
        hcaptcha.configureWebView { webview in
            webview.frame = hostView.bounds
        }
    }
}

/*import SwiftUI
import HCaptcha

/**
An empty placeholder view, that is filled with the HCaptcha UI on a button press

 - author: Klemens Muthmann
 - version: 1.0.0
 */
struct UIViewWrapperView : UIViewRepresentable {
    var uiview = UIView()

    func makeUIView(context: Context) -> UIView {
        uiview.backgroundColor = .gray
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
    //@ObservedObject var model: RegistrationViewModel
    private static let baseUrl = URL(string: "http://localhost")!
    /// The HCaptcha instance from the HCaptcha framework.
    private(set) var hcaptcha: HCaptcha!
    /// The placeholder view to fill with the HCaptcha UI.
    let placeholder = UIViewWrapperView()

    init(model: RegistrationViewModel) {
        //self.model = model
        self.hcaptcha = try? HCaptcha(apiKey: "e0055722-fb85-4130-832e-a5102c985da8", baseURL: HCaptchaView.baseUrl)
        let hostView = self.placeholder.uiview
        hcaptcha.configureWebView { webview in
            webview.frame = hostView.bounds
            model.isLoading = false
        }
        hcaptcha.onEvent { (event, data) in
            switch event {
            default:
                print(data)
            }
        }
    }

    var body: some View {
        VStack{
            placeholder.frame(width: 640, height: 640, alignment: .center)
            Button(action: {
                    //model.isLoading=true
                    hcaptcha.validate(on: placeholder.uiview) { result in
                            do {
                                let token = try result.dematerialize()
                                //model.isValidated = true
                                //model.isLoading = false
                            } catch {
                                //model.error = error
                                //model.isLoading = false
                            }
                    }
                }
            ) {
                HStack {
                    //ProgressView()
                        //.opacity(model.isLoading ? 1.0: 0.0)
                    Text("I am human")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .padding([.trailing, .leading])
            //.disabled(model.isLoading)
        }
    }
}

struct HCaptchaView_Previews: PreviewProvider {
    static var previews: some View {
        HCaptchaView(model: RegistrationViewModel())
    }
}*/
