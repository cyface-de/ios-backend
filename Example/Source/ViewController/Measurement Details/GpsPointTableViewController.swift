//
//  GpsPointTableViewController.swift
//  Cyface-Test
//
//  Created by Team Cyface on 27.11.17.
//  Copyright © 2017 Cyface GmbH. All rights reserved.
//

import UIKit
import DataCapturing
import os.log

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
            defer{OperationQueue.main.addOperation { [weak self] in
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
                PersistenceLayer.traverseTracks(ofMeasurement: measurement) {
                    track, location in locations.append(GeoLocation(latitude: location.lat, longitude: location.lon, accuracy: location.accuracy, speed: location.speed, timestamp: location.timestamp, isValid: true))
                }
                self.locations = locations
            } catch let error {
                os_log("Unable to load geo locations! Error %@", log: GpsPointTableViewController.log, type: .error, error.localizedDescription)
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
        
        let geoLocationCell = cell as! GpsPointTableViewCell
        
        geoLocationCell.timestampValueLabel.text = String(geoLocation.timestamp)
        geoLocationCell.latitudeValueLabel.text = String(format:"%.2f", geoLocation.latitude)
        geoLocationCell.longitudeValueLabel.text = String(format:"%.2f", geoLocation.longitude)
        
        return cell
    }
}
