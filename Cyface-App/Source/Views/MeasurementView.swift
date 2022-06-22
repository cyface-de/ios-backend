//
//  MeasurementView.swift
//  Cyface-App
//
//  Created by Klemens Muthmann on 17.04.22.
//

import SwiftUI

struct MeasurementView: View {

    @State private var isCurrentlyCapturing: Bool = false
    @State private var isPaused: Bool = false
    private let items = ["1", "2", "3", "4", "5", "6", "7", "8"]
    var body: some View {
        VStack {
            ScrollView {
                    ForEach(items, id: \.self) { row in
                        Text(row)
                    }
            }

            if isCurrentlyCapturing || isPaused {
                CurrentMeasurementView()
            }

            ModalitySelectorView()

            HStack {
                Button(action: {
                    isCurrentlyCapturing = true
                    isPaused = false
                }) {
                    Image("play")
                        .renderingMode(.original)
                        .padding()
                }
                .frame(maxWidth: .infinity)
                .disabled(isCurrentlyCapturing)

                Button(action: {
                    isCurrentlyCapturing = false
                    isPaused = true
                }) {
                    Image("pause")
                        .renderingMode(.original)
                        .padding()
                }
                .frame(maxWidth: .infinity)
                .disabled(isPaused || (!isPaused && !isCurrentlyCapturing))

                Button(action: {
                    isCurrentlyCapturing = false
                    isPaused = false
                }) {
                    Image("stop")
                        .renderingMode(.original)
                        .padding()
                }
                .frame(maxWidth: .infinity)
                .disabled(!isCurrentlyCapturing && !isPaused)
            }
            .frame(maxWidth: .infinity)
        }
            .navigationBarBackButtonHidden(true)
            .navigationTitle("Measurements")
            .frame(maxWidth: .infinity)
    }
}

struct MeasurementView_Previews: PreviewProvider {
    static var previews: some View {
        MeasurementView()
    }
}
