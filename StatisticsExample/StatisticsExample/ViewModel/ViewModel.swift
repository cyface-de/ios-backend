//
//  ViewModel.swift
//  StatisticsExample
//
//  Created by Klemens Muthmann on 19.01.23.
//

import DataCapturing
import CoreMotion
import CoreLocation
import CoreData

class ViewModel: NSObject, ObservableObject {
    @Published var errorMessage: String? = nil
    @Published var averageSpeed: String
    @Published var duration: String
    @Published var accumulatedHeight: String
    @Published var isStopped: Bool
    @Published var currentAltitude: String
    @Published var currentBarometricAltitude: String
    @Published var currentAbsoluteBarometricAltitude: String
    @Published var currentSpeed: String
    var dataCapturingService: DataCapturingService?
    var v11Stack: CoreDataManager?
    var coreDataStack: CoreDataManager?
    var localLocationManager: CLLocationManager?
    var altimeter: CMAltimeter?
    let altimeterQueue: OperationQueue

    override init() {
        let motionManager = CMMotionManager()
        let bundle = Bundle(for: CoreDataManager.self)
        averageSpeed = "0.00 km/h"
        duration = "0:00:00"
        accumulatedHeight = "0.0 m"
        isStopped = true
        currentAltitude = "0.0000 m"
        currentSpeed = "0.0000 km/h"
        altimeterQueue = OperationQueue()
        currentBarometricAltitude = "0.0000 m"
        currentAbsoluteBarometricAltitude = "0.0 m"
        super.init()

        localLocationManager = CLLocationManager()
        localLocationManager?.delegate = self
        altimeter = CMAltimeter()

        do {
            // Initial state
            let coreDataModel = try CoreDataManager.load(model: "CyfaceModel")
            let v11Model = try CoreDataManager.load(model: "v11model")
            let coreDataStack = CoreDataManager(storeType: NSSQLiteStoreType, modelName: "CyfaceModel", model: coreDataModel)
            self.coreDataStack = coreDataStack
            let v11Migrator = CoreDataMigrator(model: "v11model", to: .v11version9)
            let v11Stack = CoreDataManager(storeType: NSSQLiteStoreType, migrator: v11Migrator, modelName: "v11model", model: v11Model)
            self.v11Stack = v11Stack
            let initializationLock = DispatchSemaphore(value: 2)

            // Setup databases
            coreDataStack.setup(bundle: bundle) { [weak self] error in
                guard let self = self else {
                    return
                }

                if let error = error {
                    self.errorMessage = error.localizedDescription
                    return
                }

                initializationLock.signal()
            }

            v11Stack.setup(bundle: bundle) { [weak self] error in
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

                        self.averageSpeed = String(format: "%.2f km/h",measurement.averageSpeed() * 3.6)
                        let totalDuration = measurement.totalDuration()
                        self.duration = "\(totalDuration.hours()):\(String(format: "%02d", totalDuration.minutes())):\(String(format: "%02d", totalDuration.seconds()))"

                        let database = V11Database(coreDataStack: v11Stack)
                        do {
                            self.accumulatedHeight = String(format: "%.1f m", try database.summedHeight(measurement: measurement))
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
        localLocationManager?.startUpdatingLocation()
        altimeter?.startAbsoluteAltitudeUpdates(to: altimeterQueue, withHandler: handleAbsoluteAltimeterUpdate)
        altimeter?.startRelativeAltitudeUpdates(to: altimeterQueue, withHandler: handleAltimeterUpdate)

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
        localLocationManager?.stopUpdatingLocation()
        altimeter?.stopAbsoluteAltitudeUpdates()
        altimeter?.stopRelativeAltitudeUpdates()

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

extension ViewModel: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let lastLocation = locations.last {
            currentAltitude = String(format: "%.4f m", lastLocation.altitude) //String(format: "%02d m", lastLocation.altitude)
            currentSpeed = String(format: "%.4f km/h", lastLocation.speed * 3.6)
        }
    }
}

extension ViewModel {
    func handleAltimeterUpdate(data: CMAltitudeData?, error: Error?) {
        if let error = error {
            print(error.localizedDescription)
            return
        }

        guard let data = data else {
            return
        }

        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                return
            }
            self.currentBarometricAltitude = String(format: "%.4f m", data.relativeAltitude) //String(format: "%02d m", data.relativeAltitude)
        }
    }

    func handleAbsoluteAltimeterUpdate(data: CMAbsoluteAltitudeData?, error: Error?) {
        if let error = error {
            print(error.localizedDescription)
            return
        }

        guard let data = data else {
            return
        }

        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                return
            }
            self.currentAbsoluteBarometricAltitude = data.altitude.description //String(format: "%02d m", data.altitude)
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
