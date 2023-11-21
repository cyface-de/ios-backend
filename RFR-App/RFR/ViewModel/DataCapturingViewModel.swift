/*
 * Copyright 2023 Cyface GmbH
 *
 * This file is part of the Ready for Robots App.
 *
 * The Ready for Robots App is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * The Ready for Robots App is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with the Ready for Robots App. If not, see <http://www.gnu.org/licenses/>.
 */

import Foundation
import CoreMotion
import DataCapturing

/**
 The view model backing views that need to interact with the

 - Author: Klemens Muthmann
 - Version: 1.0.0
 */
class DataCapturingViewModel: ObservableObject {
    @Published var isInitialized = false
    var dataStoreStack: DataStoreStack?
    let liveViewModel: LiveViewModel
    let measurementsViewModel: MeasurementsViewModel
    let syncViewModel: SynchronizationViewModel
    let sessionRegistry = SessionRegistry()
    let authenticator: Authenticator
    private let uploadEndpoint: URL

    init(authenticator: Authenticator, uploadEndpoint: URL) throws {
        self.uploadEndpoint = uploadEndpoint
        self.authenticator = authenticator
        let dataStoreStack = try CoreDataStack()
        liveViewModel = LiveViewModel(
            dataStoreStack: dataStoreStack,
            dataStorageInterval: 5.0
        )
        syncViewModel = SynchronizationViewModel(
            authenticator: authenticator,
            dataStoreStack: dataStoreStack,
            uploadProcessBuilder: DefaultUploadProcessBuilder(
                apiEndpoint: uploadEndpoint,
                sessionRegistry: sessionRegistry
            )
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
        dataStoreStack: DataStoreStack,
        authenticator: Authenticator,
        uploadEndpoint: URL
    ) {
        self.uploadEndpoint = uploadEndpoint
        self.authenticator = authenticator
        self.isInitialized = isInitialized
        self.dataStoreStack = dataStoreStack
        liveViewModel = LiveViewModel(
            dataStoreStack: dataStoreStack,
            dataStorageInterval: 5.0
        )
        syncViewModel = SynchronizationViewModel(
            authenticator: authenticator,
            dataStoreStack: dataStoreStack, 
            uploadProcessBuilder: DefaultUploadProcessBuilder(
                apiEndpoint: uploadEndpoint,
                sessionRegistry: sessionRegistry
            )
        )
        measurementsViewModel = MeasurementsViewModel(
            dataStoreStack: dataStoreStack,
            uploadPublisher: syncViewModel.uploadStatusPublisher
        )
    }

}
