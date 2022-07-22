//
//  LabelledDivider.swift
//  Cyface-App
//
//  Created by Klemens Muthmann on 20.07.22.
//

import SwiftUI

struct LabelledDivider: View {

    let label: String
    let horizontalPadding: CGFloat = 20
    let color: Color = .gray

    var body: some View {
        HStack {
            line
            Text(label).foregroundColor(color)
            line
        }
    }

    var line: some View {
        VStack { Divider().background(color) }.padding(horizontalPadding)
    }
}
