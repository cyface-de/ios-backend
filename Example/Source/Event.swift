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

import Foundation
import UIKit
import DataCapturing

class EventItemView: UITableViewCell {

    private var _viewModel: EventItemViewModel?
    public var viewModel: EventItemViewModel? {
        get {
            return _viewModel
        }

        set {
            if let newValue = newValue {
                textLabel?.text =  newValue.modalityChange
                detailTextLabel?.text = newValue.time

                _viewModel = newValue
            } else {
                _viewModel = nil
            }
        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

class EventItemViewModel {
    let model: EventItemModel

    init(measurement: DataCapturing.Measurement, coreDataStack: CoreDataManager, position: Int) {
        self.model = EventItemModel(measurement: measurement, coreDataStack: coreDataStack, position: position)
    }

    var modalityChange: String {
        return model.modalityChange.uiString
    }

    var time: String {
        return DateFormatter.localizedString(from: model.timestamp, dateStyle: .medium, timeStyle: .medium)
    }

}

struct EventItemModel {
    let modalityChange: Modality

    let timestamp: Date

    init(measurement: DataCapturing.Measurement, coreDataStack: CoreDataManager, position: Int) {
        let persistenceLayer = PersistenceLayer(onManager: coreDataStack)

        do {
            let events = try persistenceLayer.loadEvents(typed: .modalityTypeChange, forMeasurement: measurement)

            guard let modalityValue = events[position].value else {
                fatalError("Encountered modality change without value!")
            }

            self.modalityChange = Modality.from(dbValue: modalityValue)

            guard let time = events[position].time as Date? else {
                fatalError("Encountered event without time!")
            }

            self.timestamp = time
        } catch {
            fatalError("Unable to access database!")
        }
    }
}
