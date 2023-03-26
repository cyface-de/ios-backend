//
//  ContentView.swift
//  StatisticsExample
//
//  Created by Klemens Muthmann on 18.01.23.
//

import SwiftUI
import DataCapturing

struct ContentView: View {

    @ObservedObject var viewModel: ViewModel

    var body: some View {
        if viewModel.errorMessage == nil {
            VStack {
                Spacer()
                HStack {
                    VStack(alignment: .leading) {
                        Text("Current Speed")
                        Text("Average Speed")
                        Text("Duration")
                        Text("Accumulated Height")
                        Text("Current Altitude")
                        Text("Relative Barometric Altitude")
                        Text("Absolute Barometric Altitude")
                    }
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text(viewModel.currentSpeed)
                        Text(viewModel.averageSpeed)
                        Text(viewModel.duration)
                        Text(viewModel.accumulatedHeight)
                        Text(viewModel.currentAltitude)
                        Text(viewModel.currentBarometricAltitude)
                        Text(viewModel.currentAbsoluteBarometricAltitude)
                    }
                }
                Spacer()
                HStack {
                    Button(action: viewModel.onPlayPausePressed) {
                        Image(systemName: "playpause.fill")
                    }
                    .frame(maxWidth: .infinity)
                    Button(action: viewModel.onStopPressed) {
                        Image(systemName: "stop.fill")
                    }.disabled(viewModel.isStopped)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding()
        } else {
            Text(viewModel.errorMessage ?? "No error description available!")
        }
    }

}

struct ContentView_Previews: PreviewProvider {
    private static var erroneousViewModel: ViewModel {
        let viewModel = ViewModel()
        viewModel.errorMessage = "A test Error Message"
        return viewModel
    }
    static var previews: some View {
        Group {
            ContentView(viewModel: ViewModel())
            ContentView(viewModel: erroneousViewModel)
        }
    }
}
