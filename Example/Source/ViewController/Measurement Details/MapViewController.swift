//
//  MapViewController.swift
//  Cyface-Test
//
//  Created by Team Cyface on 29.11.17.
//  Copyright © 2017 Cyface GmbH. All rights reserved.
//

import UIKit
import DataCapturing
import MapKit
import os.log

// TODO check that having open one of these VC while changing the server url actually opens the login screen again.
class MapViewController: UIViewController {
    // MARK: - Outlets
    @IBOutlet weak var mapWidget: MKMapView!
    @IBOutlet weak var eventsTableView: UITableView!
    @IBOutlet weak var editButton: UIButton!

    // MARK: - Properties
    private static let log = OSLog(subsystem: "MapViewController", category: "de.cyface")
    var measurement: Int64?
    var polyline: MKPolyline?
    var geoLocationTrackDrawer: GeoLocationTrackDrawer?

    // MARK: - Methods
    override func viewDidLoad() {
        super.viewDidLoad()

        guard let measurement = self.measurement else {
            fatalError("MapViewController.viewDidLoad(): Measurement for map view not yet properly initialized!")
        }

        let geoLocationTrackDrawer = GeoLocationTrackDrawer(forMeasurementIdentifiedBy: measurement, on: mapWidget)

        setUpTableView()
        mapWidget.delegate = geoLocationTrackDrawer
        self.geoLocationTrackDrawer = geoLocationTrackDrawer
    }

    override func viewDidAppear(_ animated: Bool) {
        eventsTableView.reloadData()
        editButton.isEnabled = false
    }

    private func setUpTableView() {
        eventsTableView.delegate = self
        eventsTableView.dataSource = self
        eventsTableView.register(EventItemView.self, forCellReuseIdentifier: cellReuseIdentifier)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier=="MapViewToMapLocationSelector" {
            guard let destination = segue.destination as? MapLocationSelectorViewController else {
                fatalError()
            }
            destination.measurementIdentifier = measurement
            destination.mapViewController = self
        } else if segue.identifier=="MapViewToModalitySelector" {
            guard let destination = segue.destination as? ModalitySelectorViewController else {
                fatalError()
            }
            destination.behaviour = {[weak self] modality in
                guard let self = self else {
                    return
                }

                guard let measurementIdentifier = self.measurement else {
                    fatalError("No measurement to change modality changes for!")
                }

                guard let indexPathForSelectedRow = self.eventsTableView.indexPathForSelectedRow else {
                    return
                }

                let persistenceLayer = PersistenceLayer(onManager: self.coreDataStack)
                do {
                    let measurement = try persistenceLayer.load(measurementIdentifiedBy: measurementIdentifier)
                    let events = try persistenceLayer.loadEvents(typed: .modalityTypeChange, forMeasurement: measurement)
                    var eventToChange = events[indexPathForSelectedRow.row]
                    eventToChange.value = modality.dbValue
                    persistenceLayer.save(measurement: measurement)
                } catch {
                    fatalError("Unable to load data from database")
                }
                self.dismiss(animated: true)
                self.eventsTableView.reloadData()
            }
            destination.cancelBehaviour = {
                self.dismiss(animated: true)
            }
        }
    }
}

// MARK: - UITableViewDelegate
extension MapViewController: UITableViewDelegate, UITableViewDataSource {
    var cellReuseIdentifier: String {
        return "eventItemCell"
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let coreDataStack = (UIApplication.shared.delegate as? AppDelegate)?.coreDataStack else {
            fatalError()
        }
        guard let measurement = measurement else {
            fatalError("No Measurement configured!")
        }

        let persistenceLayer = PersistenceLayer(onManager: coreDataStack)
        persistenceLayer.context = persistenceLayer.makeContext()

        do {
            let measurementMO = try persistenceLayer.load(measurementIdentifiedBy: measurement)
            let events = try persistenceLayer.loadEvents(typed: .modalityTypeChange, forMeasurement: measurementMO)

            return events.count
        } catch {
            fatalError("Unable to load events for current measurement!")
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell: EventItemView = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier) as? EventItemView else {
            fatalError("Unable to create/retrieve cell for event details!")
        }
        guard let coreDataStack = (UIApplication.shared.delegate as? AppDelegate)?.coreDataStack else {
            fatalError()
        }
        guard let measurement = measurement else {
            fatalError("No Measurement configured!")
        }

        let persistenceLayer = PersistenceLayer(onManager: coreDataStack)
        persistenceLayer.context = persistenceLayer.makeContext()
        do {
            let measurementMO = try persistenceLayer.load(measurementIdentifiedBy: measurement)
            cell.viewModel = EventItemViewModel(measurement: measurementMO, coreDataStack: coreDataStack, position: indexPath.row)
        } catch {
            fatalError("Unable to initilize view model for event item cell view!")
        }

        return cell
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // All but the first modality change are editable.
        return indexPath.row != 0
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {

        switch editingStyle {
        case .delete:
            do {
                try deleteEvent(at: indexPath)
                tableView.deleteRows(at: [indexPath], with: .automatic)
            } catch {
                fatalError("Unable to delete event from database")
            }
        default:
            fatalError("ViewController.tableView(\(tableView),\(editingStyle),\(indexPath)): Editing style not supported!")
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        editButton.isEnabled = true
    }

    private func deleteEvent(at index: IndexPath) throws {
        guard let measurementIdentifier = measurement else {
            fatalError("No measurement available!")
        }

        // TODO: This should probably happen in a model
        let persistenceLayer = PersistenceLayer(onManager: coreDataStack)
        persistenceLayer.context = persistenceLayer.makeContext()
        let measurement = try persistenceLayer.load(measurementIdentifiedBy: measurementIdentifier)
        let events = try persistenceLayer.loadEvents(typed: .modalityTypeChange, forMeasurement: measurement)
        let event = events[index.row]
        persistenceLayer.delete(event: event)
    }
}
