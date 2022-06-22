//
//  PrivacyPolicyView.swift
//  Cyface-App
//
//  Created by Klemens Muthmann on 19.06.22.
//

import SwiftUI
import WebKit

struct PrivacyPolicyView: UIViewRepresentable {

    let model: PrivacyPolicy

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
