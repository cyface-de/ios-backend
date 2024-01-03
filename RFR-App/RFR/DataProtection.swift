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
 A view showing the privacy declaration, loaded from the Cyface Web site.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 - Since: 3.1.2
 */
struct DataProtection: View {
    var body: some View {
        WebView(url: URL(string: "https://www.cyface.de/datenschutzbestimmung-der-app/")!)
            .navigationTitle("Datenschutz")
    }
}

#Preview {
    DataProtection()
}
