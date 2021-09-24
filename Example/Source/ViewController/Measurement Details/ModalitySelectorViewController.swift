/*
 * Copyright 2019 - 2021 Cyface GmbH
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

/**
 - Author: Klemens Muthmann
 - Version: 1.0.1
 - Since: 2.0.0
 */
class ModalitySelectorViewController: UIViewController {

    // MARK: - Outlets
    @IBOutlet weak var modalityTypesOverviewTable: UITableView!

    // MARK: - Actions
    @IBAction func tapOK(_ sender: UIButton) {
        guard let indexPathForSelectedRow = modalityTypesOverviewTable.indexPathForSelectedRow else {
            return present(selectModalityAlert, animated: true)
        }

        let selectedModality = viewModel.model[indexPathForSelectedRow.row]
        behaviour!(selectedModality)
    }

    @IBAction func tapCancel(_ sender: UIButton) {
        // This jumps back two view controllers to the beginning of the process
        cancelBehaviour!()
    }

    // MARK: - Properties
    var behaviour: ((Modality) -> Void)?
    var cancelBehaviour: (() -> Void)?

    private let viewModel = ModalitiesViewModel()
    private var selectModalityAlert: UIAlertController {
        let alert = UIAlertController(title: nothingSelectedAlertTitle, message: nothingSelectedAlertMessage, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: okAction, style: .default))
        return alert
    }

    // MARK: - Methods
    override func viewDidLoad() {
        super.viewDidLoad()

        modalityTypesOverviewTable.dataSource = self
        modalityTypesOverviewTable.delegate = self
        modalityTypesOverviewTable.register(UITableViewCell.self, forCellReuseIdentifier: cellReuseIdentifier)
        // Do any additional setup after loading the view.
    }
}

extension ModalitySelectorViewController: UITableViewDelegate, UITableViewDataSource {

    private var cellReuseIdentifier: String {
        return "modalityTypeSelectorTableCell"
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.countModalityTypes
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier) else {
            fatalError("Unable to create new cell to select modality type!")
        }

        cell.textLabel?.text = viewModel.modality[indexPath.row]

        return cell
    }

}

// TODO: Model is currently hardcoded. Should change if the number of options becomes configurable
struct ModalitiesViewModel {

    let model = [Modality.car, Modality.bike, Modality.walking, Modality.bus, Modality.train]

    var countModalityTypes: Int {
        return model.count
    }

    var modality: [String] {
        return model.map { modality in
            return modality.uiString
        }
    }
}
