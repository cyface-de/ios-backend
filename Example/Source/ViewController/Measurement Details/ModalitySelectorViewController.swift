//
//  EventTypeSelectorViewController.swift
//  Cyface
//
//  Created by Team Cyface on 22.09.19.
//  Copyright © 2019 Cyface GmbH. All rights reserved.
//

import UIKit
import DataCapturing

/**
 - Author: Klemens Muthmann
 - Version: 1.0.0
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
        // self.presentingViewController?.presentingViewController?.dismiss(animated: true)
        // presentingViewController?.dismiss(animated: true)
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
