/*
* Copyright 2019 - 2022 Cyface GmbH
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
import MapKit
import DataCapturing

/**
 A view controller that handles the selection of a geo location from a measurement track presented on a map.

 - Author: Klemens Muthmann
 - Version: 1.0.1
 - Since: 2.0.0
 */
class MapLocationSelectorViewController: UIViewController {

    // MARK: - Outlets
    @IBOutlet weak var mapWidget: MKMapView!

    // MARK: - Actions
    @IBAction func tapOnCancel(_ sender: UIBarButtonItem) {
        self.presentingViewController?.dismiss(animated: true)
    }

    // MARK: - Properties
    var measurementIdentifier: Int64?
    var measurement: DataCapturing.Measurement?
    var geoLocationTrackDrawer: GeoLocationTrackDrawer?
    var selectedPoint: GeoLocation?
    var mapViewController: MapViewController?

    // MARK: - Methods
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.geoLocationTrackDrawer = GeoLocationTrackDrawer(forMeasurementIdentifiedBy: measurementIdentifier!, on: mapWidget)
        mapWidget.delegate = geoLocationTrackDrawer
        recognizeTapsInMap()
    }

    // MARK: - Navigation

    /**
     Prepare the `ModalitySelectorViewController` by assigning appropriate behaviour.

     - Parameters:
        - for: The segue to prepare for. There is only one in this case, which is the transition from the `MapLocationSelectorViewController` to the `ModalitySelectorViewController`.
        - sender: The sender of the segue. In this class it will always be the "Select Vehicle" button.
     */
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let destination = segue.destination as? ModalitySelectorViewController else {
            fatalError()
        }

        guard let selectedPoint = selectedPoint else {
            fatalError()
        }

        guard var measurement = measurement else {
            fatalError()
        }

        let coreDataStack = self.coreDataStack

        destination.behaviour = { modality in
            let persistenceLayer = PersistenceLayer(onManager: coreDataStack)

            let timestamp = Date(timeIntervalSince1970: TimeInterval(integerLiteral: selectedPoint.timestamp / Int64(1_000)))
            do {
                _ = try persistenceLayer.createEvent(of: .modalityTypeChange, withValue: modality.dbValue, timestamp: timestamp, parent: &measurement)
            } catch {
                fatalError("\(error)")
            }

            self.presentingViewController?.dismiss(animated: true)
            if let mapViewController = self.mapViewController {
                mapViewController.eventsTableView.reloadData()
            }
        }
        destination.cancelBehaviour = {
            self.presentingViewController?.dismiss(animated: true)
        }
    }

    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        guard identifier == "MapLocationSelectorToModalitySelector" else {
            return true
        }

        if selectedPoint != nil && measurement != nil {
            return true
        } else {
            let alert = UIAlertController(title: noLocationSelectedTitle, message: noLocationSelectedMessage, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: okAction, style: .default))
            self.present(alert, animated: true)
            return false
        }
    }

    // MARK: - Methods

    private func recognizeTapsInMap() {
        super.viewDidLoad()
        // mapWidget.delegate = self
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapOnMap(sender:)))
        mapWidget.addGestureRecognizer(tapGesture)
    }

    @objc func tapOnMap(sender: UIGestureRecognizer) {
        guard let measurementIdentifier = measurementIdentifier else {
            return
        }

        if sender.state == .ended {
            let persistenceLayer = PersistenceLayer(onManager: coreDataStack)

            do {
                let measurement = try persistenceLayer.load(measurementIdentifiedBy: measurementIdentifier)

                selectedPoint = findPointClicked(sender: sender, measurement: measurement, persistenceLayer: persistenceLayer)
            } catch {
                fatalError("Unable to load measurement!")
            }
        }
    }

    private func findPointClicked(sender: UIGestureRecognizer, measurement: DataCapturing.Measurement, persistenceLayer: PersistenceLayer) -> GeoLocation? {
        guard let polyline = geoLocationTrackDrawer?.polyline else {
            return nil
        }

        let locationInView = sender.location(in: mapWidget)
        let locationOnMap = mapWidget.convert(locationInView, toCoordinateFrom: mapWidget)
        print("\(locationOnMap)")

        let point = MKMapPoint(locationOnMap)
        let mapRect = MKMapRect(x: point.x, y: point.y, width: 0, height: 0)
        var closestPoint: GeoLocation?

        if polyline.intersects(mapRect) {

            var previousSmallestDistance: Double = Double.greatestFiniteMagnitude
            let distanceCalculator = DefaultDistanceCalculationStrategy()

            PersistenceLayer.traverseTracks(ofMeasurement: measurement) { _, location in
                let distance = distanceCalculator.calculateDistance(
                    from: (location.latitude, location.longitude),
                    to: (locationOnMap.latitude, locationOnMap.longitude))
                if distance < previousSmallestDistance {
                    closestPoint = location
                    previousSmallestDistance = distance
                }
            }
        }
        return closestPoint
    }
}
