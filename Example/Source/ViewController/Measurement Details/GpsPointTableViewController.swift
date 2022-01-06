/*
 * Copyright 2017 - 2022 Cyface GmbH
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
import os.log

/**
 - Author: Klemens Muthmann
 - Version: 1.0.0
 - Since: 1.0.0
 */
class GpsPointTableViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    // MARK: - Outlets
    @IBOutlet weak var gpsPointsTableView: UITableView!

    // MARK: - Properties
    private static let log = OSLog(subsystem: "GpsPointTableViewController", category: "de.cyface")
    var locations: [GeoLocation]?
    var measurement: Int64?
    let activityIndicator = UIActivityIndicatorView(style: .gray)

    // MARK: - UIViewController
    override func viewDidLoad() {
        super.viewDidLoad()

        gpsPointsTableView.delegate = self
        gpsPointsTableView.dataSource = self
        gpsPointsTableView.backgroundView = activityIndicator
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        guard locations==nil else {
            return
        }

        guard let measurement = measurement else {
            fatalError()
        }
        activityIndicator.startAnimating()
        gpsPointsTableView.separatorStyle = .none

        guard let coreDataStack = (UIApplication.shared.delegate as? AppDelegate)?.coreDataStack else {
            fatalError()
        }

        DispatchQueue.global(qos: .userInteractive).async {
            defer {
                OperationQueue.main.addOperation { [weak self] in
                guard let self = self else {
                    return
                }

                self.activityIndicator.stopAnimating()
                self.gpsPointsTableView.separatorStyle = .singleLine
                self.gpsPointsTableView.reloadData()
                }
            }

            do {
                let persistenceLayer = PersistenceLayer(onManager: coreDataStack)
                persistenceLayer.context = persistenceLayer.makeContext()

                var locations = [GeoLocation]()

                let measurement = try persistenceLayer.load(measurementIdentifiedBy: measurement)
                PersistenceLayer.traverseTracks(ofMeasurement: measurement) {_, location in
                    locations.append(GeoLocation(
                        latitude: location.lat,
                        longitude: location.lon,
                        accuracy: location.accuracy,
                        speed: location.speed,
                        timestamp: location.timestamp,
                        isValid: true))
                }
                self.locations = locations
            } catch let error {
                os_log("Unable to load geo locations! Error %{public}@",
                       log: GpsPointTableViewController.log,
                       type: .error, error.localizedDescription)
            }
        }

    }

    // MARK: - UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let locations=locations {
            return locations.count
        } else {
            return 0
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: "GpsPointTableViewCell", for: indexPath)
        let geoLocation = locations![indexPath.row]

        guard let geoLocationCell = cell as? GpsPointTableViewCell else {
            fatalError()
        }

        geoLocationCell.timestampValueLabel.text = String(geoLocation.timestamp)
        geoLocationCell.latitudeValueLabel.text = String(format: "%.2f", geoLocation.latitude)
        geoLocationCell.longitudeValueLabel.text = String(format: "%.2f", geoLocation.longitude)

        return cell
    }
}
