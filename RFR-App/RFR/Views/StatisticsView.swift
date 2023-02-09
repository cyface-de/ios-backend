/*
 * Copyright 2023 Cyface GmbH
 *
 * This file is part of the Read-for-Robots iOS App.
 *
 * The Read-for-Robots iOS App is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * The Read-for-Robots iOS App is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with the Read-for-Robots iOS App. If not, see <http://www.gnu.org/licenses/>.
 */

import SwiftUI

/**
 A view showing statistics about all the measurements captured by this device.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 */
struct StatisticsView: View {
    var body: some View {
            List {

                Section(header: Text("Maximale Strecke")) {
                    KeyValueView(key: "Distanz", value: "214.2 km (\u{2205} 38.2 km)")
                    KeyValueView(key: "Dauer", value: "2 T 14 h 12 min (\u{2205} 23 min)")
                }

                Section(header: Text("Höhe")) {
                    KeyValueView(key: "Tiefster Punkt", value: "104 m")
                    KeyValueView(key: "Höchster Punkt", value: "2.203 m")
                    KeyValueView(key: "Anstieg", value: "max 2.1 km (\u{2205} 720 m)")
                }

                Section(header: Text("Vermiedener CO\u{2082} Ausstoß")) {
                    KeyValueView(key: "Gesamt", value: "17,3 kg")
                    KeyValueView(key: "Maximal", value: "1,5 kg (\u{2205} 0,9 kg)")
                }
            }
    }
}

struct StatisticsView_Previews: PreviewProvider {
    static var previews: some View {
        StatisticsView()
    }
}


