/*
 * Copyright 2023-2024 Cyface GmbH
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
 - Version: 2.0.0
 - Since: 3.1.2
 */
class DataCapturingViewModel: ObservableObject {
    // MARK: - Properties
    /// The stack used to access the data store.
    var dataStoreStack: DataStoreStack?
    /// The view model used by the view for controlling the live measurement.
    let liveViewModel: LiveViewModel
    /// The view model used to show information about the captured measurements.
    let measurementsViewModel: MeasurementsViewModel
    /// The view model used to handle measurement synchronization.
    let syncViewModel: SynchronizationViewModel
    // TODO: All of this only concerns the `SynchronizationViewModel` and thus should only appear there.
    /// The authenticator used to authenticate for data uploads
    let authenticator: Authenticator

    // MARK: - Initializers
    init(authenticator: Authenticator, uploadProcessBuilder: UploadProcessBuilder, dataStoreStack: DataStoreStack) throws {
        self.authenticator = authenticator

        liveViewModel = LiveViewModel(
            dataStoreStack: dataStoreStack,
            dataStorageInterval: 5.0
        )
        syncViewModel = SynchronizationViewModel(
            authenticator: authenticator,
            dataStoreStack: dataStoreStack,
            uploadProcessBuilder: uploadProcessBuilder
        )
        measurementsViewModel = MeasurementsViewModel(
            dataStoreStack: dataStoreStack,
            uploadPublisher: syncViewModel.uploadStatusPublisher
        )
        measurementsViewModel.subscribe(to: liveViewModel.$message)
        self.dataStoreStack = dataStoreStack
        try dataStoreStack.wrapInContext { context in
            let request = MeasurementMO.fetchRequest()
            request.predicate = NSPredicate(format: "synchronized=false AND synchronizable=false")
            let result = try request.execute()
            for measurementModelObject in result {
                measurementModelObject.synchronizable = true
            }
            try context.save()
        }
        try measurementsViewModel.setup()
    }

    init(
        showError: Bool,
        dataStoreStack: DataStoreStack,
        authenticator: Authenticator,
        collectorUrl: URL
    ) {
        self.authenticator = authenticator
        self.dataStoreStack = dataStoreStack
        liveViewModel = LiveViewModel(
            dataStoreStack: dataStoreStack,
            dataStorageInterval: 5.0
        )
        syncViewModel = SynchronizationViewModel(
            authenticator: authenticator,
            dataStoreStack: dataStoreStack,
            uploadProcessBuilder: DefaultUploadProcessBuilder(
                collectorUrl: collectorUrl,
                sessionRegistry: DefaultSessionRegistry(),
                uploadFactory: CoreDataBackedUploadFactory(dataStoreStack: dataStoreStack)
            )
        )
        measurementsViewModel = MeasurementsViewModel(
            dataStoreStack: dataStoreStack,
            uploadPublisher: syncViewModel.uploadStatusPublisher
        )
    }

}
