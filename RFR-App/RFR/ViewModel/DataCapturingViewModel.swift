//
//  DataCapturingViewModel.swift
//  RFR
//
//  Created by Klemens Muthmann on 13.03.23.
//

import Foundation
import DataCapturing
import CoreMotion
import DataCapturing
import OSLog

class DataCapturingViewModel: ObservableObject {
    @Published var isInitialized = false
    @Published var showError = false
    @Published var username = ""
    @Published var password = ""
    var error: Error? {
        didSet {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else {
                    return
                }

                self.showError = true
            }
        }
    }
    var dataCapturingService: DataCapturingService?

    init() {
        do {
            let coreDataStack = try CoreDataManager()
            Task {
                do {
                    try await coreDataStack.setup()
                    dataCapturingService = DataCapturingServiceImpl(
                        lifecycleQueue: DispatchQueue(label: "lifecylce"),
                        capturingQueue: DispatchQueue.global(qos: .userInitiated),
                        savingInterval: TimeInterval(1.0),
                        coreDataStack: coreDataStack
                    )
                    DispatchQueue.main.async { [weak self] in
                        guard let self = self else {
                            return
                        }

                        self.isInitialized = true
                    }
                } catch {
                    handleError(error)
                }
            }
        } catch {
            handleError(error)
        }
    }

    init(
        isInitialized: Bool,
        showError: Bool,
        username: String,
        password: String,
        error: Error?,
        dataCapturingService: DataCapturingService
    ) {
        self.isInitialized = isInitialized
        self.showError = showError
        self.username = username
        self.password = password
        self.error = error
        self.dataCapturingService = dataCapturingService
    }

    // TODO: Add events to handle (especially geo location information and status of data capturing)
    func handle(event: DataCapturingEvent, status: Status) {
        switch status {
        case .success:
            switch event {
            default:
                os_log("Unhandled data capturing event %@!",log: OSLog.capturingEvent, type: .info, event.description)
            }
        case .error(let error):
            handleError(error)
        }
    }

    func synchronize() {
        // TODO: Implement data synchronization.
    }

    private func handleError(_ error: Error) {
        self.error = error
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                return
            }

            self.showError = true
        }
    }
}
