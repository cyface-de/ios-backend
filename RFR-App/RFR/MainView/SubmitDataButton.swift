/*
 * Copyright 2024 Cyface GmbH
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

import SwiftUI
import DataCapturing

/**
 A button to start synchronizing unsynchronized measurements

 - Author: Klemens Muthmann
 - Version: 1.0.0
 */
struct SubmitDataButton: View {
    /// The view model providing functions to synchronize data.
    @ObservedObject var syncViewModel: SynchronizationViewModel

    var body: some View {
        Button(action: {
            Task {
                await syncViewModel.synchronize()
            }
        }) {
            Label("Daten übertragen", systemImage: "icloud.and.arrow.up")
                .labelStyle(.titleAndIcon)
        }
    }
}

#if DEBUG

#Preview {
    let mockDataStoreStack = MockDataStoreStack()
    let mockApiUrl = URL(string: "http://localhost:8080/api/v4")!
    let mockUploadProcessBuilder = MockUploadProcessBuilder(
        apiEndpoint: mockApiUrl,
        sessionRegistry: DefaultSessionRegistry()
    )
    let measurementsViewModel = MeasurementsViewModel(dataStoreStack: mockDataStoreStack)

    return SubmitDataButton(
        syncViewModel: SynchronizationViewModel(
            dataStoreStack: mockDataStoreStack,
            uploadProcessBuilder: mockUploadProcessBuilder,
            measurementsViewModel: measurementsViewModel
        )
    )
}
#endif
