//
//  CyfaceTextField.swift
//  Cyface-App
//
//  Created by Klemens Muthmann on 30.03.22.
//

import SwiftUI

struct CyfaceTextField: TextFieldStyle {

    public func _body(configuration field: TextField<_Label>) -> some View {
        field/*.textFieldStyle(.roundedBorder)*/
            .autocapitalization(.none)
            .disableAutocorrection(true)
    }
}
