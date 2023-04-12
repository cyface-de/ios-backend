//
//  DataCapturingViewModel.swift
//  RFR
//
//  Created by Klemens Muthmann on 13.03.23.
//

import Foundation
import CoreMotion
import DataCapturing

class DataCapturingViewModel: ObservableObject {
    @Published var isInitialized = false
    @Published var showError = false
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
            let coreDataStack = try CoreDataStack()
            Task {
                do {
                    try await coreDataStack.setup()
                    dataCapturingService = DataCapturingServiceImpl(
                        lifecycleQueue: DispatchQueue(label: "lifecylce"),
                        capturingQueue: DispatchQueue.global(qos: .userInitiated),
                        savingInterval: TimeInterval(1.0),
                        dataStoreStack: coreDataStack
                    )
                    DispatchQueue.main.async { [weak self] in
                        self?.isInitialized = true
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
        error: Error?,
        dataCapturingService: DataCapturingService
    ) {
        self.isInitialized = isInitialized
        self.showError = showError
        self.error = error
        self.dataCapturingService = dataCapturingService
    }

    private func handleError(_ error: Error) {
        self.error = error
        DispatchQueue.main.async { [weak self] in
            self?.showError = true
        }
    }
}
