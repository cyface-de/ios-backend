//
//  StatisticsViewController.swift
//  Cyface-Test
//
//  Created by Team Cyface on 29.11.17.
//  Copyright © 2017 Cyface GmbH. All rights reserved.
//

import UIKit
import DataCapturing
import Charts
import os.log

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
            os_log("StatisticsViewController.updateChartWithData(): Measurement not yet initialized!", log: StatisticsViewController.LOG, type: .error)
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
            os_log("StatisticsViewController.updateChartWithData(): Unable to load accelerations! Error %@", log: StatisticsViewController.LOG, type: .error, error.localizedDescription)
        }
    }
}

// MARK: - ChartViewDelegate
extension StatisticsViewController: ChartViewDelegate {
    
}
