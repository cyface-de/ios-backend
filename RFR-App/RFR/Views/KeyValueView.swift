//
//  KeyValueView.swift
//  RFR
//
//  Created by Klemens Muthmann on 31.01.23.
//

import SwiftUI

struct KeyValueView: View {
    var key: String
    var value: String

    var body: some View {
        HStack {
            Text(key)
            Spacer()
            Text(value)
                .foregroundColor(Color.gray)
                .frame(alignment: .trailing)
                .font(.callout)
        }
    }
}

struct KeyValueView_Previews: PreviewProvider {
    static var previews: some View {
        KeyValueView(key: "testkey", value: "testvalue")
    }
}
