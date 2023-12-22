/*
 * Copyright 2023 Cyface GmbH
 *
 * This file is part of the Ready for Robots iOS App.
 *
 * The Ready for Robots iOS App is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * The Ready for Robots iOS App is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with the Ready for Robots iOS App. If not, see <http://www.gnu.org/licenses/>.
 */
import SwiftUI

/**
 View showing the imprint and links to privacy exaplanations.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 - Since: 3.1.2
 */
struct ImpressumView: View {
    var body: some View {
        List {
            Section(header: Text("Herausgeber")) {
                Text("""
Cyface GmbH
Behringstraße 46
01159 Dresden
Deutschland
""")
                Text("""
Vertreten durch:
Dr. Klemens Muthmann
""")
                Text("""
E-Mail: mail@cyface.de
Telefon: +49 351 6 475 2580
""")
                Text("""
Amtsgericht Dresden
HRB: 36726
USt.-Id.: DE-312598748
""")
            }
            Section(header: Text("Haftungshinweis")) {
                Text("""
Trotz sorgfältiger inhaltlicher Kontrolle übernehmen wir keine Haftung für die Inhalte externer Links. Für den Inhalt der verlinkten Seiten sind ausschließlich deren Betreiber verantwortlich.
""")
            }

                    Section(header: Text("Datenschutz")) {
                        NavigationLink("Datenschutzbestimmungen") {
                            DataProtection()
                        }

            }
        }.navigationTitle("Impressum")

    }
}

#if DEBUG
#Preview {
    ImpressumView()
}
#endif
