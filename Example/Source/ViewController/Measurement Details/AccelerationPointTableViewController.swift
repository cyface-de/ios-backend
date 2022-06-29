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
 Controls the display of accelerations in a `UITableView`. Initially the view shows an activity indicator, while loading accelerations asynchronously from the database.

 - Author: Klemens Muthmann
 - Version: 1.0.3
 - Since: 1.0.0
 */
class AccelerationPointTableViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    // MARK: - Outlets
    @IBOutlet weak var accelerationsTableView: UITableView!

    // MARK: - Properties
    private static let LOG = OSLog(subsystem: "AccelerationPointTableViewController", category: "View")
    var accelerations: [SensorValue]?
    var measurement: Int64?
    let activityIndicator = UIActivityIndicatorView(style: .gray)

    // MARK: - UIViewController
    override func viewDidLoad() {
        super.viewDidLoad()

        accelerationsTableView.dataSource = self
        accelerationsTableView.delegate = self

        accelerationsTableView.backgroundView=activityIndicator
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        guard accelerations==nil else {
            return
        }

        activityIndicator.startAnimating()
        accelerationsTableView.separatorStyle = .none

        guard let entity = measurement else {
            fatalError()
        }

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
                    self.accelerationsTableView.separatorStyle = .singleLine
                    self.accelerationsTableView.reloadData()
                }
            }

            do {
                let persistenceLayer = PersistenceLayer(onManager: coreDataStack)

                let measurement = try persistenceLayer.load(measurementIdentifiedBy: entity)

                let accelerationFile = SensorValueFile(fileType: SensorValueFileType.accelerationValueType)
                self.accelerations = try accelerationFile.load(from: measurement)

            } catch let error {
                os_log("Unable to initializer persistence layer! Error %{public}@",
                       log: AccelerationPointTableViewController.LOG,
                       type: .error, error.localizedDescription)
            }
        }
    }

    // MARK: - UITableViewDataSource
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "AccelerationPointTableViewCell", for: indexPath)
        guard let tableViewCell = cell as? AccelerationPointTableViewCell else {
            fatalError()
        }
        tableViewCell.set(accelerationPoint: accelerations![indexPath.row])

        return tableViewCell
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let accelerations = accelerations {
            return accelerations.count
        } else {
            return 0
        }
    }
}
