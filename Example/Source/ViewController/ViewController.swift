/*
 * Copyright 2017 - 2021 Cyface GmbH
 *
 * This file is part of the Cyface SDK for iOS.
 *
 * The Cyface SDK for iOS is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * The Cyface SDK for iOS is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with the Cyface SDK for iOS. If not, see <http://www.gnu.org/licenses/>.
 */

import UIKit
import DataCapturing
import CoreMotion
import CoreLocation
import os.log

/**
The view controller showing the overview of unsynchronized measurements together with the controls to capture new measurements.

 This is still an MVC (Massive View Controller) until all the remining pieces of business logic are refactored out to their own view models. Of special importance is to remove all calls to the persistence layer from this view controller.

 - Author: Klemens Muthmann
 - Version: 2.1.0
 - Since: 1.0.0
 */
class ViewController: UIViewController {

    // MARK: - Actions
    /**
     Called on each tap on the start button. This starts a measurement if non is running or continues a paused one, otherwise it should be disabled.

     - Parameter sender: The `UIButton` instance that was tapped on
     */
    @IBAction func onStartTapped(_ sender: UIButton) {
        guard let dataCapturingService = dataCapturingService else {
            fatalError("ViewController.onStartTapped(\(sender.debugDescription)): No DataCapturingService available!")
        }

        disablePlayButton()
        disableStopButton()
        disablePauseButton()

        if dataCapturingService.isPaused && !dataCapturingService.isRunning {
            do {
                try dataCapturingService.resume()
            } catch {
                fatalError("Unable to resume")
            }
            enablePauseButton()
            disablePlayButton()
            enableStopButton()
        } else if !dataCapturingService.isPaused && !dataCapturingService.isRunning {
            guard let modalityValue = UserDefaults.standard.string(forKey: "de.cyface.settings.context") else {
                fatalError("No modality set!")
            }

            os_log("Service was not running. Starting now!", log: ViewController.LOG, type: .info)
            do {
                try dataCapturingService.start(inMode: modalityValue)
            } catch {
                fatalError("Unable to start.")
            }

        } else {
            fatalError("Service is in invalid state: paused --> \(dataCapturingService.isPaused), running --> \(dataCapturingService.isRunning)" )
        }

    }
    /**
     Called on each tap on the pause button. This pauses a running measurement, otherwise it should be disabled.

     - Parameter sender: The `UIButton` instance that was tapped on
     */
    @IBAction func onPauseTapped(_ sender: UIButton) {
        guard let dataCapturingService = dataCapturingService else {
            fatalError("No DataCapturingService available!")
        }

        disablePauseButton()
        enablePlayButton()
        enableStopButton()

        if dataCapturingService.isRunning {
            os_log("Service was running. Pausing now!", log: ViewController.LOG, type: .info)
            do {
                try dataCapturingService.pause()
            } catch {
                fatalError("Unable to pause.")
            }
        } else {
            os_log("Service was not running. Not pausing!",
                   log: ViewController.LOG,
                   type: .info)
        }
    }
    /**
     Called on each tap on the stop button: This stops a running or paused measurement, otherwise it should be disabled.

     - Parameter sender: The `UIButton` instance that was tapped on
     */
    @IBAction func onStopTapped(_ sender: UIButton) {
        guard let dataCapturingService = dataCapturingService else {
            fatalError("ViewController.onStopTapped(\(sender.debugDescription)): No DataCapturingService available!")
        }

        disablePauseButton()
        enablePlayButton()
        disableStopButton()

        if dataCapturingService.isRunning {
            os_log("Service was running. Stopping now!", log: ViewController.LOG, type: .info)
            do {
                try dataCapturingService.stop()
            } catch {
                fatalError("Unable to stop.")
            }

        } else {
            os_log("ViewController.onStopTapped(%@): Service was not running. Not stopping!",
                   log: ViewController.LOG,
                   type: .info, sender.debugDescription)
        }
        measurementsOverview.reloadData()
    }
    /**
     Called if the force upload button was tapped. This starts synchronization of all unsynchronized measurements immediately, even if the app is not connected to a WiFi.

     - Parameter sender: The `UIButton` instance that was tapped on
     */
    @IBAction func forceUploadTapped(_ sender: UIBarButtonItem) {
        synchronizer.sync()
    }
    /**
     Called if the selector for transporation modes was tapped. This should change the current mode of transportation.

     - Parameter sender: The `UIButton` instance that was tapped on
     */
    @IBAction func selectContextTapped(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            set(mode: Modality.car)
        case 1:
            set(mode: Modality.bike)
        case 2:
            set(mode: Modality.walking)
        case 3:
            set(mode: Modality.bus)
        case 4:
            set(mode: Modality.train)
        default:
            fatalError("ViewController.selectContextTapped(_:): Index \(sender.selectedSegmentIndex) not supported!")
        }

    }

    // MARK: - Outlets
    @IBOutlet weak var measurementsOverview: UITableView!
    @IBOutlet weak var pauseButton: UIButton!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var stopButton: UIButton!
    @IBOutlet weak var contextTabBar: UISegmentedControl!
    @IBOutlet weak var mainAreaStackView: UIStackView!

    // MARK: - Properties
    var dataCapturingService: DataCapturingService?

    private lazy var synchronizer: Synchronizer = {
        guard let coreDataStack = appDelegate.coreDataStack else {
            fatalError("Unable to load CoreData stack!")
        }
        guard let serverConnection = appDelegate.serverConnection else {
            fatalError("Unable to load server connection!")
        }

        let ret = Synchronizer(
        coreDataStack: coreDataStack,
        cleaner: DeletionCleaner(),
        serverConnection: serverConnection) { [weak self] event, status in
            guard let self = self else {
                return
            }
            switch event {
            case .synchronizationStarted(let measurementIdentifier):
                self.synchronizing(measurementIdentifier: measurementIdentifier, status: status)
            case .synchronizationFinished(let measurementIdentifier):
                self.synchronized(measurementIdentifier: measurementIdentifier, status: status)
            default:
                fatalError("Received an event which is not processable!")
            }
        }
        return ret
    }()
    var measurements: [TableCellViewModel] = []
    // private var synchronizingMeasurements: [Int64] = []
    private static let LOG = OSLog(subsystem: "ViewController", category: "de.cyface")
    private var overlayView: UIView?
    private var activityIndicator: UIActivityIndicatorView?
    /// A variable saving the previous state of the synchronizer toggle. Since it is not possible to observe a specific property, it is necessary to save this so we can see if the value has changed and activate or deactivate the synchronizer based on that information.
    private var synchronizerWasPreviouslyActivated: Bool = false
    private var lifecycle: CapturingLifecycle!
    /// Provides access to this apps system settings, some of which are hidden and some of which are presented via the iOS settings app.
    var settings: Settings?
    /// An internal unwrapped convenience variable for the system settings.
    private var _settings: Settings {
        guard let settings = settings else {
            fatalError("Unable to load settings. ViewController was not properly initialized!")
        }

        return settings
    }

    // MARK: - Methods
    /**
     This is the core method for handling all events returned by the Cyface SDK.

     This method is called each time the Cyface SDK reports an event processable by the user interface.
     Please see `DataCapturingEvent` enumeration for possible events.

     - Parameter event: The event that triggered the call to this method
     - Parameter status: The status of the received event. This is either `success` or `error`
     */
    func handleDataCapturingEvent(event: DataCapturingEvent, status: Status) {

        switch event {
        case .serviceStarted(let measurementIdentifier, _):
            guard let measurementIdentifier = measurementIdentifier else {
                fatalError()
            }

            lifecycle.onServiceStarted(appDelegate: appDelegate, status: status, measurementIdentifier: measurementIdentifier)

        case .geoLocationAcquired(position: _):
            DispatchQueue.main.async { [weak self] in
                guard let self = self else {
                    return
                }

                // TODO: Maybe use the provided location instead of loading it from the database.
                self.lifecycle.onGeoLocationAcquired()
            }

        case .serviceStopped:
            DispatchQueue.main.async { [weak self] in
                guard let self = self else {
                    return
                }

                self.lifecycle.onServiceStopped(synchronizer: self.synchronizer, synchronize: self._settings.synchronizeData)
            }

        case .servicePaused:
            os_log("Service Paused", log: ViewController.LOG, type: .debug)

        case .serviceResumed(let measurementIdentifier, _):
            guard let measurementIdentifier = measurementIdentifier else {
                fatalError()
            }

            self.lifecycle.onServiceResumed(appDelegate: appDelegate, status: .success, measurementIdentifier: measurementIdentifier)
        case .geoLocationFixAcquired:
            self.lifecycle.onGeoLocationFixStatusChanged(true)
        case .geoLocationFixLost:
            self.lifecycle.onGeoLocationFixStatusChanged(false)
        default:
            fatalError("Unexpected DataCapturingEvent!")
        }
    }

    /**
     This is called after a measurement has been successfully synchronized. It must run on the main thread to update the UI.

     - Parameters:
        - measurementIdentifier: The measurement that was synchronized
        - status: Status of whether the synchronization was successful or not.
     */
    func synchronized(measurementIdentifier: Int64, status: Status) {
        debugPrint("Finishing synchronization for measurement \(measurementIdentifier).")
        // Search the index of the synchronizing measurement in the list of shown measurements.
        guard let (index, measurement) = self.findMeasurementCellViewModelBy(identifier: measurementIdentifier) else {
            fatalError("No measurement with identifier \(measurementIdentifier)!")
        }

        guard measurement.status == .uploading else {
            fatalError("Measurement in invalid state. Expected .uploading but got \(measurement.status)")
        }

        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                return
            }

            switch status {
            case .success:
                measurement.status = .uploadSuccessful
                // TODO: Move the following code to a separate view class
                let path = IndexPath(row: index, section: 0)

                self.measurements.remove(at: path.row)

                self.measurementsOverview.beginUpdates()
                self.measurementsOverview.deleteRows(at: [path], with: .automatic)
                self.measurementsOverview.endUpdates()
            case .error(let error as ServerConnectionError):
                _ = ServerConnectionError.handle(error: error)
                measurement.status = .uploadFailed
            case .error(let error):
                print("Unexpected Error! \(error)")
                measurement.status = .uploadFailed
            }

            // Finally refresh the view.
            self.measurementsOverview.reloadData()
        }
    }

    /**
     A function called when a measurement starts to synchronize with the server.

     - Parameters:
        - measurement: The identifier of the measurement that is being synchronized.
        - status: The status of the measurement, that is being synchronized.
     */
    func synchronizing(measurementIdentifier: Int64, status: Status) {
        guard case .success = status else {
            if case .error(let error) = status {
                os_log("ViewController.handleDataCapturingEvent(:DataCapturingEvent:Status): Error status: @%",
                       log: ViewController.LOG,
                       type: .error, error.localizedDescription)
            }
            return
        }

        guard let (_, measurement) = findMeasurementCellViewModelBy(identifier: measurementIdentifier) else {
            fatalError("No measurement with identifier \(measurementIdentifier)")
        }

        debugPrint("Starting synchronization for measurement \(measurement).")
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                return
            }

            measurement.status = MeasurementCellStatus.uploading
            self.measurementsOverview.reloadData()
        }
    }

    @objc
    func onSynchronizationToggleChanged(_ notification: Notification) {
        // Activate and deactivate the synchronizer based on the property value.
        let synchronizerIsNotActive = _settings.synchronizeData
        if synchronizerIsNotActive && !synchronizerWasPreviouslyActivated {
            synchronizer.activate()
        } else if !synchronizerIsNotActive && synchronizerWasPreviouslyActivated {
            synchronizer.deactivate()
        } else {
            // Probably some other setting has changed, so ignoring this call.
            return
        }
    }

    func disablePauseButton() {
        pauseButton.isEnabled = false
        pauseButton.isUserInteractionEnabled = false
    }

    func disablePlayButton() {
        playButton.isEnabled = false
        playButton.isUserInteractionEnabled = false
    }

    func disableStopButton() {
        stopButton.isEnabled = false
        stopButton.isUserInteractionEnabled = false
    }

    func enablePauseButton() {
        pauseButton.isEnabled = true
        pauseButton.isUserInteractionEnabled = true
    }

    func enablePlayButton() {
        playButton.isEnabled = true
        playButton.isUserInteractionEnabled = true
    }

    func enableStopButton() {
        stopButton.isEnabled = true
        stopButton.isUserInteractionEnabled = true
    }

    func showOverlay(completion: (() -> Void)?) {
        let alert = UIAlertController(
            title: nil,
            message: NSLocalizedString("Please wait...", comment: "Shown when loading the main view."),
            preferredStyle: .alert)

        let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.style = UIActivityIndicatorView.Style.gray
        loadingIndicator.startAnimating()

        alert.view.addSubview(loadingIndicator)
        present(alert, animated: true, completion: completion)
    }

    func hideOverlayView(completion: (() -> Void)?) {
        dismiss(animated: false, completion: completion)
    }

    // MARK: - UIViewController
    override func viewDidLoad() {
        super.viewDidLoad()
        // TODO: This should move into a proper constructor if this is changed to MVVM with programmatical UI
        synchronizerWasPreviouslyActivated = _settings.synchronizeData

        // Required for the extensions methods (see below) to fire appropriately.
        measurementsOverview.delegate = self
        measurementsOverview.dataSource = self

        lifecycle = CapturingLifecycle(controller: self)

        let modalityValue = UserDefaults.standard.string(forKey: "de.cyface.settings.context")
        switch modalityValue {
        case Modality.car.dbValue:
            contextTabBar.selectedSegmentIndex = 0
        case Modality.bike.dbValue:
            contextTabBar.selectedSegmentIndex = 1
        case Modality.walking.dbValue:
            contextTabBar.selectedSegmentIndex = 2
        case Modality.bus.dbValue:
            contextTabBar.selectedSegmentIndex = 3
        case Modality.train.dbValue:
            contextTabBar.selectedSegmentIndex = 4
        default:
            os_log("Unsupported measurement context %{PUBLIC}@! This message is harmless if it occurs on the first App start!",
                   log: OSLog.init(subsystem: "ViewController",
                                   category: "de.cyface"),
                   type: .default, String(describing: modalityValue))
            contextTabBar.selectedSegmentIndex = 1
            UserDefaults.standard.set(Modality.bike.dbValue, forKey: "de.cyface.settings.context")
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if measurements.isEmpty {
            showOverlay {
                let coreDataStack = self.coreDataStack
                DispatchQueue.global(qos: .userInteractive).async {
                    defer {
                        DispatchQueue.main.async { [weak self] in
                            guard let self = self else {
                                return
                            }

                            self.initialButtonState()
                            self.hideOverlayView(completion: nil)
                        }
                    }

                    do {
                        // Init DataCapturingService
                        let motionManager = CMMotionManager()
                        self.dataCapturingService = DataCapturingService(
                            sensorManager: motionManager,
                            dataManager: coreDataStack,
                            eventHandler: self.handleDataCapturingEvent)

                        // TODO: Move this to a Table View Model
                        // Load the measurements to show
                        let persistenceLayer = PersistenceLayer(onManager: coreDataStack)
                        persistenceLayer.context = persistenceLayer.makeContext()
                        let measurements = try persistenceLayer.loadSynchronizableMeasurements()

                        for measurement in measurements {
                            let model = MeasurementModel(coreDataStack)
                            model.measurement = measurement
                            let cellViewModel = TableCellViewModel(model: model)
                            self.measurements.append(cellViewModel)
                        }

                        DispatchQueue.main.async { [weak self] in
                            guard let self = self else {
                                return
                            }

                            self.measurementsOverview.reloadData()
                        }
                    } catch {
                        fatalError()
                    }
                }
            }
        }

        if _settings.synchronizeData {
            synchronizer.activate()
        }
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(onSynchronizationToggleChanged(_:)),
                                               name: UserDefaults.didChangeNotification,
                                               object: nil)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        if _settings.synchronizeData {
            synchronizer.deactivate()
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)

        // Only continue if we have a segue identifier
        guard let segueIdentifier = segue.identifier else {
            fatalError("Tried to call segue without identifier!")
        }

        // Only continue with correct segue identifier
        guard segueIdentifier == "ShowMeasurementDetailsSegue" else {
            fatalError("Unknown segue \(segueIdentifier) called!")
        }

        // Only continue with correct segue destination
        guard let destination = segue.destination as? MeasurementDetailsViewController else {
            fatalError("Unknow destination for segue \(segueIdentifier)!")
        }

        guard let senderCell = sender as? TableCellView else {
            fatalError("Segue \(segueIdentifier) called from invalid sender element!")
        }

        guard let indexPath = measurementsOverview.indexPath(for: senderCell) else {
            fatalError("The selected cell is not being displayed by the measurements overview table!")
        }

        measurements[indexPath.row].sendTo(controller: destination)
    }

    // MARK: - Private Methods
    /**
     Sets the pause, play and stop button to the correct state after this view controller appears on the screen.
     */
    private func initialButtonState() {
        guard let dataCapturingService = dataCapturingService else {
            fatalError("Expected initialized capturing service!")
        }

        // Check if there was a paused measurement and enable resuming it.
        if dataCapturingService.isPaused {
            enableStopButton()
            disablePauseButton()
            enablePlayButton()
        }
        disableStopButton()
        disablePauseButton()
        enablePlayButton()
    }
    /**
     Changes the current mode of transportation.

     - Parameter mode: The new transportation mode to change to
     */
    private func set(mode: Modality) {
        UserDefaults.standard.set(mode.dbValue, forKey: "de.cyface.settings.context")
        dataCapturingService?.changeModality(to: mode.dbValue)
    }
    /**
     Searches the array of  `TableCellViewModel` instances for the one displaying a `Measurement` with the provided `identifier`.

     - Parameter identifier: The locally unique identifier of the measurement to search for
     - TODO: This could be removed if there would be a proper table view model using a dictionary to store the `TableCellViewModel` instances
     - Returns: A tuple containing the index of the found view model and the view model itself or `nil` if no matching view model was found
     */
    private func findMeasurementCellViewModelBy(identifier: Int64) -> (Int, TableCellViewModel)? {
        for (index, measurement) in measurements.enumerated() {
            if measurement.showsMeasurement(measurementIdentifier: identifier) {
                return (index, measurement)
            }
        }
        return nil
    }
}

// MARK: - UITableViewDelegate and UITableViewDataSource
extension ViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let viewModel = measurements[indexPath.row]

        guard let cell = tableView.dequeueReusableCell(withIdentifier: "measurementCell") as? TableCellView else {
            fatalError("Unable to find reusable cell for identifier \"measurementCell\".")
        }

        cell.configureFrom(viewModel: viewModel)

        return cell
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return measurements.count
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {

        switch editingStyle {
        case .delete:
                let measurement = measurements[indexPath.row]
                measurement.delete {
                    DispatchQueue.main.async { [weak self] in
                        guard let self = self else {
                            return
                        }

                        self.measurements.remove(at: indexPath.row)
                        tableView.deleteRows(at: [indexPath], with: .fade)
                    }
                }

        default:
            fatalError("ViewController.tableView(\(tableView),\(editingStyle),\(indexPath)): Editing style not supported!")
        }
    }
}
