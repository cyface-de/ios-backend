//
//  SwiftUIView.swift
//  Cyface-App
//
//  Created by Klemens Muthmann on 28.04.22.
//

import SwiftUI

struct ModalitySelectorView: View {
    @State private var selectedModality: Modalities = Modalities.defaultSelection

    var body: some View {
        Picker("Modality", selection: $selectedModality) {
            Text(Modalities.bicycle.uiValue).tag(Modalities.bicycle)
            Text(Modalities.car.uiValue).tag(Modalities.car)
            Text(Modalities.walking.uiValue).tag(Modalities.walking)
            Text(Modalities.bus.uiValue).tag(Modalities.bus)
            Text(Modalities.train.uiValue).tag(Modalities.train)
        }.pickerStyle(.segmented)
    }
}

struct ModalitySelectorView_Previews: PreviewProvider {
    static var previews: some View {
        ModalitySelectorView()
    }
}
