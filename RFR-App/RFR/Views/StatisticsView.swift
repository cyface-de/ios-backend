//
//  StatisticsView.swift
//  RFR
//
//  Created by Klemens Muthmann on 26.01.23.
//

import SwiftUI

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


