//
//  AccelerationPointTableViewCell.swift
//  Cyface-Test
//
//  Created by Team Cyface on 27.11.17.
//  Copyright © 2017 Cyface GmbH. All rights reserved.
//

import UIKit
import DataCapturing

class AccelerationPointTableViewCell: UITableViewCell {
    @IBOutlet weak var timestampValue: UILabel!
    @IBOutlet weak var zValue: UILabel!
    @IBOutlet weak var xValue: UILabel!
    @IBOutlet weak var yValue: UILabel!
    
    func set(accelerationPoint value: SensorValue) {
        let formattedTimestamp = DateFormatter.localizedString(from: value.timestamp, dateStyle: .short, timeStyle: .short)
        timestampValue.text = formattedTimestamp
        zValue.text = String(format: "%.2f", value.z)
        xValue.text = String(format: "%.2f", value.x)
        yValue.text = String(format: "%.2f", value.y)
    }

}
