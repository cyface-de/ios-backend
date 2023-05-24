//
//  LoadinScreen.swift
//  RFR
//
//  Created by Klemens Muthmann on 13.03.23.
//

import SwiftUI

/**
 A view shown during initial app setup.
 */
struct LoadinScreen: View {
    var body: some View {
        ProgressView()
    }
}

#if DEBUG
struct LoadinScreen_Previews: PreviewProvider {
    static var previews: some View {
        LoadinScreen()
    }
}
#endif
