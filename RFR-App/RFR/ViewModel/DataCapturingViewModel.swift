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
    var dataStoreStack: DataStoreStack?
    let liveViewModel: LiveViewModel
    let measurementsViewModel: MeasurementsViewModel
    let syncViewModel: SynchronizationViewModel
    let sessionRegistry = SessionRegistry()

    init() throws {
            let dataStoreStack = try CoreDataStack()
            liveViewModel = LiveViewModel(
                dataStoreStack: dataStoreStack,
                dataStorageInterval: 5.0
            )
            syncViewModel = SynchronizationViewModel(
                dataStoreStack: dataStoreStack,
                apiEndpoint: URL(string: RFRApp.uploadEndpoint)!,
                sessionRegistry: sessionRegistry
            )
            measurementsViewModel = MeasurementsViewModel(
                dataStoreStack: dataStoreStack,
                uploadPublisher: syncViewModel.uploadStatusPublisher
            )
            measurementsViewModel.subscribe(to: liveViewModel)
            self.dataStoreStack = dataStoreStack
            Task {
                try await dataStoreStack.setup()
                try measurementsViewModel.setup()
                DispatchQueue.main.async { [weak self] in
                    self?.isInitialized = true
                }
            }
    }

    init(
        isInitialized: Bool,
        showError: Bool,
        dataStoreStack: DataStoreStack
    ) {
        self.isInitialized = isInitialized
        self.dataStoreStack = dataStoreStack
        liveViewModel = LiveViewModel(
            dataStoreStack: dataStoreStack,
            dataStorageInterval: 5.0
        )
        syncViewModel = SynchronizationViewModel(
            dataStoreStack: dataStoreStack,
            apiEndpoint: URL(string: RFRApp.uploadEndpoint)!,
            sessionRegistry: sessionRegistry
        )
        measurementsViewModel = MeasurementsViewModel(
            dataStoreStack: dataStoreStack,
            uploadPublisher: syncViewModel.uploadStatusPublisher
        )
    }

}
