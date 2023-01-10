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
import WebKit

/**
 The view used to show the privacy policy on first app start and each time the text changes.

 The privacy policy is shown as an HTML page view a `WKWebView`.

 - author: Klemens Muthmann
 - version: 1.0.0
 */
struct PrivacyPolicyView: UIViewRepresentable {

    /// The view model used.
    let model: PrivacyPolicy

    /// Create a new view from the provided system settings.
    init(settings: Settings) {
        model = PrivacyPolicy(settings)
    }

    func makeUIView(context: Context) -> WKWebView {
       return WKWebView()
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        let request = URLRequest(url: model.privacyPolicyUrl)
        uiView.load(request)
    }
}
