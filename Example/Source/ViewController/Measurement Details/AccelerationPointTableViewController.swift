//
//  AccelerationPointTableViewController.swift
//  Cyface-Test
//
//  Created by Team Cyface on 27.11.17.
//  Copyright © 2017 Cyface GmbH. All rights reserved.
//

import UIKit
import DataCapturing
import os.log

/**
 Controls the display of accelerations in a `UITableView`. Initially the view shows an activity indicator, while loading accelerations asynchronously from the database.

 - Author: Klemens Muthmann
 - Version: 1.0.1
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
                persistenceLayer.context = persistenceLayer.makeContext()

                let measurement = try persistenceLayer.load(measurementIdentifiedBy: entity)

                let accelerationFile = SensorValueFile(fileType: SensorValueFileType.accelerationValueType)
                self.accelerations = try accelerationFile.load(from: measurement)

            } catch let error {
                os_log("Unable to initializer persistence layer! Error %@",
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
