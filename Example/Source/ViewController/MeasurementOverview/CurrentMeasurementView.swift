/*
 * Copyright 2018 - 2021 Cyface GmbH
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

/**
 The view shown while a measurement is active

 - Author: Klemens Muthmann
 - Version: 1.0.1
 - Since: 2.0.0
 */
class CurrentMeasurementView: UIStackView {
    /// The label containing the name of the currently captured measurement
    var measurementNameLabel = UILabel()
    /// The content view for the current geo location fix status. This displays either an icon showing that there is a geo location fix or another icon showing that there is none
    var hasFixContent = UIImageView()
    /// A label showing the distance traveled on the active measurement
    var distanceTraveledContent = UILabel()
    /// A label showing the current speed of the active measurement
    var speedContent = UILabel()
    /// A label showing the current duration of the active measurement
    var timeContent = UILabel()
    /// A label showing the latitude of the last captured position
    var lastLatContent = UILabel()
    /// A label showing the longitude of the last captured position
    var lastLonContent = UILabel()

    // initWithFrame to init view from code
    /**
     Creates a new display for the current measurement

     - Parameters:
        - parent: The `ViewController` used to embed the display in
        - viewModel: The view model to load the displayed data from
     */
    convenience init(parent: ViewController, viewModel: CurrentMeasurementViewModel) {
        self.init(frame: CGRect.zero)

        translatesAutoresizingMaskIntoConstraints = false
        measurementNameLabel.translatesAutoresizingMaskIntoConstraints = false
        let boldFont = UIFont(descriptor: UIFontDescriptor.preferredFontDescriptor(withTextStyle: .title1), size: 0)
        measurementNameLabel.attributedText = NSAttributedString.init(
            string: viewModel.currentMeasurementLabel,
            attributes: [NSAttributedString.Key.font: boldFont])
        setColorFor(label: measurementNameLabel)

        axis = .vertical
        addArrangedSubview(measurementNameLabel)
        spacing = 5.0

        let topRowStackView = UIStackView()
        addArrangedSubview(topRowStackView)
        topRowStackView.translatesAutoresizingMaskIntoConstraints = false
        topRowStackView.axis = .horizontal
        topRowStackView.distribution = .fillEqually
        topRowStackView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        topRowStackView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        topRowStackView.spacing = 5.0

        let middleRowStackView = UIStackView()
        addArrangedSubview(middleRowStackView)
        middleRowStackView.translatesAutoresizingMaskIntoConstraints = false
        middleRowStackView.axis = .horizontal
        middleRowStackView.distribution = .fillEqually
        middleRowStackView.spacing = 5.0

        let bottomRowStackView = UIStackView()
        addArrangedSubview(bottomRowStackView)
        bottomRowStackView.translatesAutoresizingMaskIntoConstraints = false
        bottomRowStackView.axis = .horizontal
        bottomRowStackView.distribution = .fillEqually
        bottomRowStackView.spacing = 5.0

        addInformation(labelText: NSLocalizedString("GPS Fix", comment: ""), content: hasFixContent, parent: topRowStackView)
        hasFixContent.image = viewModel.hasFix
        hasFixContent.contentMode = .center
        addInformation(labelText: NSLocalizedString("Trip Distance", comment: ""), content: distanceTraveledContent, parent: middleRowStackView)
        distanceTraveledContent.text = viewModel.distance
        distanceTraveledContent.textAlignment = .right
        addInformation(labelText: NSLocalizedString("Speed", comment: ""), content: speedContent, parent: bottomRowStackView)
        speedContent.text = viewModel.speed
        speedContent.textAlignment = .right

        addInformation(labelText: NSLocalizedString("Duration", comment: ""), content: timeContent, parent: topRowStackView)
        timeContent.text = viewModel.timestamp
        timeContent.textAlignment = .right
        addInformation(labelText: NSLocalizedString("Latitude", comment: ""), content: lastLatContent, parent: middleRowStackView)
        lastLatContent.text = viewModel.lastLat
        lastLatContent.textAlignment = .right
        addInformation(labelText: NSLocalizedString("Longitude", comment: ""), content: lastLonContent, parent: bottomRowStackView)
        lastLonContent.text = viewModel.lastLon
        lastLonContent.textAlignment = .right

        parent.mainAreaStackView.insertArrangedSubview(self, at: 2)
    }

    /**
     Initializer used and required by iOS framework. This should never be called directly.

     - Parameter frame: The frame to show the display in
     */
    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    // initWithCode to init view from xib or storyboard
    /**
     Initializer used for storiebords and XIB files. This should never be called directly.

     - Parameter coder: An `NSCoder` used to deserialize the view
     */
    required init(coder aDecoder: NSCoder) {
        fatalError("Init with decoder is unsupported!")
    }

    /**
     Removes this view from the view hierarchy it is embedded in
     */
    func destroy() {
        removeFromSuperview()
    }

    /**
     Adds one piece of information about the current measurement to the display

     - Parameters:
        - labelText: The label used to describe the information
        - content: A `UIView` used to display the actual information
        - parent: The parent view to display the information in
     */
    private func addInformation(labelText: String, content: UIView, parent: UIStackView) {
        let informationStackView = UIStackView()
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        informationStackView.addArrangedSubview(label)
        label.text = labelText
        content.translatesAutoresizingMaskIntoConstraints = false
        informationStackView.addArrangedSubview(content)
        parent.addArrangedSubview(informationStackView)
        setColorFor(label: label)
        if #available(iOS 13.0, *) {
            content.backgroundColor = .systemBackground
        }
    }

    /**
     Updates the view with the most recent information.

     - Parameters:
        - viewModel: The view model to update the view from
     */
    func update(viewModel: CurrentMeasurementViewModel) {
        hasFixContent.image = viewModel.hasFix
        distanceTraveledContent.text = viewModel.distance
        speedContent.text = viewModel.speed
        timeContent.text = viewModel.timestamp
        lastLonContent.text = viewModel.lastLon
        lastLatContent.text = viewModel.lastLat
    }

    private func setColorFor(label: UILabel) {
        if #available(iOS 13.0, *) {
            label.textColor = .label
            label.backgroundColor = .systemBackground
        }
    }
}
