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
import Charts
import os.log

/**
 - Author: Klemens Muthmann
 - Version: 1.0.0
 - Since: 1.0.0
 */
class StatisticsViewController: UIViewController {
    // MARK: - Outlets
    @IBOutlet weak var dataView: LineChartView!

    // MARK: - Properties
    private static let LOG = OSLog(subsystem: "StatisticsViewController", category: "View")
    var measurement: Int64?

    // MARK: - Initializers
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.initialize()
    }

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        self.initialize()
    }

    // MARK: - Methods
    private func initialize() {
        self.edgesForExtendedLayout = []
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        updateChartWithData()
    }

    func updateChartWithData() {
        guard let entity = self.measurement else {
            os_log("Measurement not yet initialized!", log: StatisticsViewController.LOG, type: .error)
            return
        }

        do {
            guard let coreDataStack = (UIApplication.shared.delegate as? AppDelegate)?.coreDataStack else {
                fatalError()
            }
            let persistenceLayer = PersistenceLayer(onManager: coreDataStack)
            persistenceLayer.context = persistenceLayer.makeContext()

            let measurement = try persistenceLayer.load(measurementIdentifiedBy: entity)

            var dataEntries: [ChartDataEntry] = []
            let accelerationFile = SensorValueFile(fileType: SensorValueFileType.accelerationValueType)
            let accelerations = try accelerationFile.load(from: measurement).prefix(100)

            for point in accelerations {
                dataEntries.append(ChartDataEntry(x: point.timestamp.timeIntervalSince1970, y: point.z))
            }

            let chartDataSet = LineChartDataSet(entries: dataEntries, label: NSLocalizedString("Z-Axis Accelerations", comment: ""))
            let chartData = LineChartData(dataSet: chartDataSet)

            DispatchQueue.main.async { [weak self] in
                guard let self = self else {
                    return
                }

                self.dataView.data = chartData
            }
        } catch let error {
            os_log("Unable to load accelerations! Error %{public}@", log: StatisticsViewController.LOG, type: .error, error.localizedDescription)
        }
    }
}

// MARK: - ChartViewDelegate
extension StatisticsViewController: ChartViewDelegate {

}
