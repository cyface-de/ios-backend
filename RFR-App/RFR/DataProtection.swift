//
//  DataProtection.swift
//  RFR
//
//  Created by Klemens Muthmann on 29.11.23.
//

import SwiftUI

struct DataProtection: View {
    var body: some View {
        WebView(url: URL(string: "https://www.cyface.de/datenschutzbestimmung-der-app/")!)
            .navigationTitle("Datenschutz")
    }
}

#Preview {
    DataProtection()
}
