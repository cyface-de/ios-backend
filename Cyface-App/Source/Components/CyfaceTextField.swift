//
//  CyfaceTextField.swift
//  Cyface-App
//
//  Created by Klemens Muthmann on 30.03.22.
//

import SwiftUI

struct CyfaceTextField: View {

    var label: String
    var binding: Binding<String>

    var body: some View {
        TextField(label, text: binding)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .autocapitalization(.none)
    }
}

struct CyfaceTextField_Previews: PreviewProvider {
    @State static var bind = ""

    static var previews: some View {

        CyfaceTextField(label: "Light", binding: $bind).preferredColorScheme(.light)
        CyfaceTextField(label: "Dark", binding: $bind).preferredColorScheme(.dark)
    }
}
