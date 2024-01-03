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
import SwiftUI

// TODO: Remove this and exchange with alert modifier
/**
 A view to display any error message.
 */
struct ErrorView: View {
    /// The error to display information for.
    let error: Error
    
    var body: some View {
        ErrorTextView(errorMessage: error.localizedDescription)
    }
}

#if DEBUG
#Preview {
    ErrorView(error: RFRError.missingAuthenticator)
}
#endif
