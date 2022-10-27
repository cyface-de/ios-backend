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

/**
A horizontal line with a lable in the center.

 - author: Klemens Muthmann
 - version: 1.0.0
 */
struct LabelledDivider: View {
    /// The label to show in the center of the line.
    let label: String
    /// Padding to the left and the right.
    let horizontalPadding: CGFloat = 20
    /// Color of the line and the text.
    let color: Color = .gray

    var body: some View {
        HStack {
            line
            Text(label).foregroundColor(color)
            line
        }
    }

    /// The line part to the left and the right of the label.
    var line: some View {
        VStack { Divider().background(color) }.padding(horizontalPadding)
    }
}
