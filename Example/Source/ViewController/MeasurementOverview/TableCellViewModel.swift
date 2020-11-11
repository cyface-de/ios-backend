//
// Copyright (C) 2018 - 2020 Cyface GmbH - All Rights Reserved
// Unauthorized copying of this file, via any medium is strictly prohibited
// Proprietary and confidential
//

import Foundation

/**
 The view model backing a single cell or row in the table view displaying the overview of the not synchronized measurements.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 - Since: 3.1.0
 */
class TableCellViewModel {
    // MARK: - Properties
    /// The formatter used to format the length representation of a measurement.
    private static var numberFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.alwaysShowsDecimalSeparator = true
        formatter.maximumFractionDigits = 3
        formatter.usesGroupingSeparator = true
        formatter.minimumFractionDigits = 3
        formatter.minimumIntegerDigits = 1
        formatter.locale = Locale.current
        return formatter
    }
    /// The model backing this view model.
    private var model: MeasurementModel
    /// The titel of the measurement as appearing in the user interface.
    var title: String {
        guard let identifier = model.identifier else {
            fatalError("Unable to load identifier from model!")
        }

        let comment = "Measurement string shown in the table with unsynchronized measuremens in the main view."
        return "\(NSLocalizedString("measurementInTableCell", comment: comment)) \(identifier)"
    }
    /// The length of the measurement as appearing in the user interface.
    var length: String {
        guard let distance = model.distance else {
            fatalError("Unable to load distance from model!")
        }

        let distanceInKilometers = distance / 1_000.0
        return "\(TableCellViewModel.numberFormatter.string(from: NSNumber(floatLiteral: distanceInKilometers)) ?? "0.0") km"
    }
    /// The status of the measurement of this cell.
    var status: MeasurementCellStatus {
        didSet {
            statusChanged?(status)
        }
    }
    /// The identifier of the measurement shown by this table cell. This needs to be cached here to clean up the UI after deleting the measurement from the database.
    let measurementIdentifier: Int64

    // MARK: - Bindings
    /// A closure listeners can bind to, which is called each time the `status` changes. That way the UI can carry out proper refresh logic.
    var statusChanged: ((MeasurementCellStatus) -> Void)?

    // MARK: - Initializers
    /**
     Creates a new completely initialized object of this class based on a backing model

     - Parameter model: The model backing this view model
     */
    init(model: MeasurementModel) {
        self.model = model
        self.status = .unsynchronized
        guard let identifier = model.identifier else {
            fatalError("Unable to load model for view model!")
        }
        self.measurementIdentifier = identifier
    }
    // MARK: - Methods
    /**
     Checks whether this view model displays a measurement with the provided measurement identifier or not.

     - Parameter measurementIdentifier: The identifier to check for
     - Returns: `true` if the measurement shown by this view model has to provided `measurementIdentifier`; `false` otherwise
     */
    func showsMeasurement(measurementIdentifier: Int64) -> Bool {
        return self.measurementIdentifier == measurementIdentifier
    }
    /**
     This is an ugly helper method, which should be removed as soon as the whole MeasurementDetailsViewController is refactored to MVVM.
     It is required at the moment, since the `MeasurementDetailsViewController` still expects to receive a measurement identifier as a poor mans model.

     - Parameter controller: The `MeasurementDetailsViewController` to send the measurement clicked on to
     */
    func sendTo(controller: MeasurementDetailsViewController) {
        controller.measurement = model.identifier
    }
    /**
     Delete the view model together with the backing measurement.
     */
    func delete(onDeleted: () -> Void) {
        model.delete {
            onDeleted()
        }
    }
}
