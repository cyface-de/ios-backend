//
//  MainView.swift
//  RFR
//
//  Created by Klemens Muthmann on 31.01.23.
//

import SwiftUI

struct MainView: View {
    var body: some View {
        NavigationStack {
            TabView {
                MeasurementsView(measurements: exampleMeasurements)
                    .tabItem {
                        Image(systemName: "square.3.layers.3d")
                        Text("Fahrten")
                            .font(.footnote)
                    }
                LiveView(viewModel: viewModelExample)
                    .tabItem {
                        Image(systemName: "play")
                        Text("Live")
                    }
                StatisticsView()
                    .tabItem {
                        Image(systemName: "chart.xyaxis.line")
                        Text("Statistiken")
                            .font(.footnote)
                    }
            }
            .toolbar {
                Button(action: {print("Daten übertragen")}) {
                    VStack {
                        Image(systemName: "icloud.and.arrow.up")
                        Text("Daten übertragen")
                            .font(.footnote)
                    }
                }
            }
        }
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
