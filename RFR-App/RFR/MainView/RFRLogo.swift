/*
 * Copyright 2024 Cyface GmbH
 *
 * This file is part of the Ready for Robots App.
 *
 * The Ready for Robots App is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * The Ready for Robots App is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with the Ready for Robots App. If not, see <http://www.gnu.org/licenses/>.
 */

import SwiftUI

/**
 The logo of the Ready for Robots project to be displayed in the upper left corner of the application

 - Author: Klemens Muthmann
 - Version: 1.0.0
 */
struct RFRLogo: View {
    var body: some View {
        HStack {
            // This is an ugly workaround from Stackoverflow.
            // Appaerantly it is impossible to scale the logo correctly any other way.
            Text("Logo")
                .font(.title)
                .foregroundStyle(.clear)
                .overlay {
                    Image("RFR-Logo")
                        .resizable()
                        .scaledToFill()
                        .padding(.leading)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Logo")
            Spacer()
        }
    }
}

#Preview {
    RFRLogo()
}
