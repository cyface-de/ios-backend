//
//  CyfaceButton.swift
//  Cyface-App
//
//  Created by Klemens Muthmann on 30.03.22.
//

import SwiftUI

struct CyfaceButton: ButtonStyle {

    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.bold(.body)()).foregroundColor(.primary).padding().background(Color("Cyface-Green")).cornerRadius(15)
    }
}
