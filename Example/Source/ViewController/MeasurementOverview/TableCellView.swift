//
// Copyright (C) 2018 - 2020 Cyface GmbH - All Rights Reserved
// Unauthorized copying of this file, via any medium is strictly prohibited
// Proprietary and confidential
//

import UIKit
import DataCapturing
import os.log

/**
 Represents a single cell in the measurements overview list on the main screen of the Cyface iOS app.

 The Cyface iOS app contains a list with all the measurements currently stored locally on the device. An instance of this class represents one entry from that list showing the measurement name and the currently travelled distance in kilometers.

 - Author: Klemens Muthmann
 - Version: 2.0.0
 - Since: 1.0.0
 */
class TableCellView: UITableViewCell {
    // MARK: - Outlets
    /// The label displaying the measurements title. This is currently something like "Measurement 1".
    @IBOutlet weak var label: UILabel!
    /// A container view displaying status information about the measurement.
    @IBOutlet weak var measurementStatusView: UIView!
    /// The label displaying the length of the measurement.
    @IBOutlet weak var distanceLabel: UILabel!

    // MARK: - Propertiess
    /// The logger used by objects of this class
    private static let log = OSLog(subsystem: "TableCellView", category: "de.cyface")

    // MARK: - Methods
    /**
     Configures this view from its corresponding view model.

     - Parameter viewModel: The view model providing the values for this `TableCellView`
     */
    func configureFrom(viewModel: TableCellViewModel) {
        label.text = viewModel.title
        distanceLabel.text = viewModel.length
        viewModel.statusChanged = { status in
            DispatchQueue.main.async { [weak self] in
                guard let self = self else {
                    return
                }

                self.set(status: status)
            }
        }
    }

    /**
     Sets the status view in `measurementStatusView` to the correct value based on the current status.

     - Parameter status: The status of the measurement displayed by this view
     */
    private func set(status: MeasurementCellStatus) {
        // Remove all existing subviews
        for subview in measurementStatusView.subviews {
            subview.removeFromSuperview()
        }

        switch(status) {
        case .uploading:
            debugPrint("Formatting table cell for synchronizing measurement!")
            let activityIndicatorView = UIActivityIndicatorView(style: .gray)
            add(statusSubview: activityIndicatorView)
            activityIndicatorView.startAnimating()
        case .uploadFailed:
            let image = UIImage(named: "error")
            let playView = UIImageView(image: image)
            playView.contentMode = .scaleAspectFit
            add(statusSubview: playView)
        default:
            os_log("Switching to status with no view.", log: TableCellView.log, type: .debug)
        }
    }

    /**
     Adds a new status subview to the `measurementStatusView`.

     - Parameters:
        - statusSubview: The root of the view with the UI tree representing the statusSubview
     */
    private func add(statusSubview subView: UIView) {
        // Add new status subview centered in parent
        subView.translatesAutoresizingMaskIntoConstraints = false

        measurementStatusView.addSubview(subView)
        let centerXConstraint = NSLayoutConstraint(item: subView, attribute: .centerX, relatedBy: .equal, toItem: measurementStatusView, attribute: .centerX, multiplier: 1.0, constant: 0)
        let centerYConstraint = NSLayoutConstraint(item: subView, attribute: .centerY, relatedBy: .equal, toItem: measurementStatusView, attribute: .centerY, multiplier: 1.0, constant: 0)

        measurementStatusView.addConstraints([centerXConstraint, centerYConstraint])
    }
}
