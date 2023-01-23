//
//  ViewModel.swift
//  StatisticsExample
//
//  Created by Klemens Muthmann on 19.01.23.
//

import DataCapturing
import CoreMotion

class ViewModel: ObservableObject {
    @Published var errorMessage: String? = nil
    @Published var averageSpeed: String
    @Published var duration: String
    @Published var accumulatedHeight: String
    @Published var isStopped: Bool
    var dataCapturingService: DataCapturingService?
    var v11Stack: CoreDataManager?
    var coreDataStack: CoreDataManager?

    init() {
        let motionManager = CMMotionManager()
        let bundle = Bundle(for: CoreDataManager.self)
        averageSpeed = "0.0 km/h"
        duration = "0:00:00"
        accumulatedHeight = "0 m"
        isStopped = true
        do {
            // Initial state
            let coreDataModel = try CoreDataManager.load(model: "CyfaceModel")
            let v11Model = try CoreDataManager.load(model: "v11model")
            let coreDataStack = CoreDataManager(modelName: "CyfaceModel", model: coreDataModel)
            self.coreDataStack = coreDataStack
            let v11Stack = CoreDataManager(modelName: "v11model", model: v11Model)
            self.v11Stack = v11Stack
            let initializationLock = DispatchSemaphore(value: 2)

            // Setup databases
            try coreDataStack.setup(bundle: bundle) { [weak self] error in
                guard let self = self else {
                    return
                }

                if let error = error {
                    self.errorMessage = error.localizedDescription
                    return
                }

                initializationLock.signal()
            }

            try v11Stack.setup(bundle: bundle) { [weak self] error in
                guard let self = self else {
                    return
                }

                if let error = error {
                    self.errorMessage = error.localizedDescription
                    return
                }

                initializationLock.signal()
            }

            // Finish evertything with either error handling or setup of the data capturing service.
            if initializationLock.wait(timeout: DispatchTime.now() + 5) == .timedOut {
                errorMessage = "Initialization timed out!"
            } else {
                dataCapturingService = DataCapturingService(
                    sensorManager: motionManager,
                    dataManager: coreDataStack,
                    v11Stack: v11Stack,
                    eventHandler: on
                )

                isStopped = (!(dataCapturingService?.isRunning ?? false) && !(dataCapturingService?.isPaused ?? false))
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func on(capturingEvent: DataCapturingEvent, status: Status) {
        switch status {
        case .success:
            switch capturingEvent {
            case .serviceStarted(_, _):
                DispatchQueue.main.async { [weak self] in
                    self?.isStopped = false
                }
            case .servicePaused(_, _):
                DispatchQueue.main.async { [weak self] in
                    self?.isStopped = false
                }
            case .serviceResumed(_, _):
                DispatchQueue.main.async { [weak self] in
                    self?.isStopped = false
                }
            case .serviceStopped(_, _):
                DispatchQueue.main.async { [weak self] in
                    self?.isStopped = true
                }
            case .geoLocationAcquired(_):
                guard let measurementIdentifier = dataCapturingService?.currentMeasurement else {
                    return
                }
                guard let coreDataStack = coreDataStack else {
                    return
                }
                guard let v11Stack = v11Stack else {
                    return
                }
                let persistenceLayer = PersistenceLayer(onManager: coreDataStack)
                do {
                    let measurement = try persistenceLayer.load(measurementIdentifiedBy: measurementIdentifier)
                    DispatchQueue.main.async { [weak self] in
                        guard let self = self else {
                            return
                        }

                        self.averageSpeed = "\(String(format: "%.2f",measurement.averageSpeed()/3.6)) km/h"
                        let totalDuration = measurement.totalDuration()
                        self.duration = "\(totalDuration.hours()):\(String(format: "%02d", totalDuration.minutes())):\(String(format: "%02d", totalDuration.seconds()))"

                        let database = V11Database(coreDataStack: v11Stack)
                        do {
                            self.accumulatedHeight = "\(String(format: "%.1f", try database.summedHeight(measurement: measurement))) m"
                        } catch {
                            self.errorMessage = error.localizedDescription
                        }
                    }
                } catch {
                    errorMessage = error.localizedDescription
                }
            default:
                print("Unhandled Event \(capturingEvent.description)")
            }
        case .error(let error):
            errorMessage = error.localizedDescription
        }
    }

    func onPlayPausePressed() {
        guard let dataCapturingService = dataCapturingService else {
            return
        }

        do {
            if dataCapturingService.isRunning {
                try dataCapturingService.pause()
            } else if dataCapturingService.isPaused {
                try dataCapturingService.resume()
            } else {
                try dataCapturingService.start(inMode: "BYCICLE")
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func onStopPressed() {
        guard let dataCapturingService = dataCapturingService else {
            return
        }

        do {
            try dataCapturingService.stop()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

extension TimeInterval {
    func hours() -> Int {
        return Int(self / 3600)
    }

    func minutes() -> Int {
        return Int((self / 60).truncatingRemainder(dividingBy: 60))
    }

    func seconds() -> Int {
        return Int(self.truncatingRemainder(dividingBy: 60))
    }
}
