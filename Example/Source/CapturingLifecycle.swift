//
//  CapturingLifecycle.swift
//  Cyface
//
//  Created by Team Cyface on 07.06.19.
//  Copyright © 2019 Cyface GmbH. All rights reserved.
//

import Foundation
import DataCapturing
import os.log

class CapturingLifecycle {

    private static let log = OSLog(subsystem: "de.cyface", category: "CapturingLifecycle")
    let viewController: ViewController
    var currentMeasurementView: CurrentMeasurementView?
    var currentMeasurementViewModel: CurrentMeasurementViewModel?

    init(controller: ViewController) {
        self.viewController = controller
    }

    func onServiceStarted(appDelegate: AppDelegate, status: Status, measurementIdentifier: Int64) {
        switch status {
        case .success:
            do {
                try showCurrentMeasurementOverlay(in: appDelegate, for: measurementIdentifier)

                DispatchQueue.main.async {
                    self.viewController.enableStopButton()
                    self.viewController.enablePauseButton()
                }
            } catch {
                return os_log("ViewController.handleDataCapturingEvent(event: .serviceStarted, status: .success): Error: %@",
                              log: CapturingLifecycle.log,
                              type: .error, error.localizedDescription)
            }

        case .error(let error):
            os_log("ViewController.handleDataCapturingEvent(event: .serviceStarted, status: .error): Error: %@",
                   log: CapturingLifecycle.log,
                   type: .error, error.localizedDescription)
        }
    }

    /**
     Function called if service has successfully resumed data capturing.

     - Parameters:
        - appDelegate: The `AppDelegate` running this application
        - status: Status on whether resume was successful or not (Currently this is always `.success`, otherwise the method would not have been called.
        - measurementIdentifier: The device wide unique identifier of the measurement the service has resumed to measure.
    */
    func onServiceResumed(appDelegate: AppDelegate, status: Status, measurementIdentifier: Int64) {
        switch status {
        case .success:
            do {
                try showCurrentMeasurementOverlay(in: appDelegate, for: measurementIdentifier)
            } catch {
                return os_log("ViewController.handleDataCapturingEvent(event: .serviceResumed, status: .success): Error: %@",
                              log: CapturingLifecycle.log,
                              type: .error, error.localizedDescription)
            }
        case .error(let error):
            os_log("ViewController.handleDataCapturingEvent(event: .serviceResumed, status: .error): Error: %@",
                   log: CapturingLifecycle.log,
                   type: .error, error.localizedDescription)
        }
    }

    /**
     Called each time a new geo location has been acquired.
     */
    func onGeoLocationAcquired() {
        guard let currentMeasurementView = currentMeasurementView else {
            return
        }

        guard let currentMeasurementViewModel = currentMeasurementViewModel else {
            fatalError("The current measurement view model was not properly initialized!")
        }

        currentMeasurementView.update(viewModel: currentMeasurementViewModel)
    }

    /**
     Called each time the status of geo location fixes changed.

     - Parameter newStatus: The new fix status, which is `true` if there currently is a geo location fix and `false` otherwise.
     */
    func onGeoLocationFixStatusChanged(_ newStatus: Bool) {
        guard let currentMeasurementViewModel = currentMeasurementViewModel else {
            fatalError("The current measurement view model was not properly initialized!")
        }

        currentMeasurementViewModel.changeFixStatus(to: newStatus)
    }

    /**
     Called each time the service has stopped successfully. This should only be called on the **MainThread**.

     - Parameter synchronizer: The synchronizer to used to transmit the stopped measurement to a Cyface server.
     */
    func onServiceStopped(synchronizer: Synchronizer) {
        guard let currentMeasurementViewModel = currentMeasurementViewModel else {
            fatalError("Current Measurement view not initialized!")
        }

        let cellViewModel = currentMeasurementViewModel.finish()
        viewController.measurements.append(cellViewModel)

        if let currentMeasurementView = self.currentMeasurementView {
            currentMeasurementView.destroy()
        }
        self.currentMeasurementViewModel = nil
        self.currentMeasurementView = nil

        self.viewController.measurementsOverview.reloadData()
        if UserDefaults.standard.bool(forKey: AppDelegate.syncToggleKey) { synchronizer.syncChecked()
        }

        os_log("Service stopped", log: CapturingLifecycle.log, type: .info)
    }

    /**
     Displays the details view for the currently captured measurement.

     - Parameters:
        - in: The application to access the database from
        - for: The device wide unique identifier of the currently captured measurement
     */
    private func showCurrentMeasurementOverlay(in app: AppDelegate, for measurementIdentifiedBy: Int64) throws {
        guard currentMeasurementViewModel == nil else {
            return
        }

        guard currentMeasurementView == nil else {
            return
        }

        guard let coreDataStack = app.coreDataStack else {
            fatalError()
        }
        let persistenceLayer = PersistenceLayer(onManager: coreDataStack)
        persistenceLayer.context = persistenceLayer.makeContext()

        let measurement = try persistenceLayer.load(measurementIdentifiedBy: measurementIdentifiedBy)

        os_log("ViewController.handleDataCapturingEvent(:DataCapturingEvent:Status): Capturing measurement %@.",
               log: CapturingLifecycle.log,
               type: .info, "\(measurementIdentifiedBy)")

        let currentMeasurement = MeasurementModel(coreDataStack)

        currentMeasurement.measurement = measurement
        let currentMeasurementViewModel = CurrentMeasurementViewModel(currentMeasurement)

        viewController.mainAreaStackView.translatesAutoresizingMaskIntoConstraints = false

        currentMeasurementView = CurrentMeasurementView(parent: self.viewController, viewModel: currentMeasurementViewModel)
        self.currentMeasurementViewModel = currentMeasurementViewModel
    }
}
