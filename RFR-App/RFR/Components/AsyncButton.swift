/*
 * Copyright 2022 Cyface GmbH
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
import SwiftUI

/**
 A button, that shows a spinner icon, while the action it triggered is processed.

 - author: Klemens Muthmann
 - version: 1.0.0
 */
struct AsyncButton<Label: View>: View {
    /// The action to trigger, when this button is pressed.
    var action: () async -> Void
    /// The modifications to the button while it is waiting for the result of the triggered action.
    var actionOptions = Set(ActionOption.allCases)
    /// The label to show on the button.
    @ViewBuilder var label: () -> Label

    /// The starting state of being disabled.
    @State private var isDisabled = false
    /// The starting state of showing a progress view.
    @State private var showProgressView = false

    var body: some View {
        Button(
            action: {
                if actionOptions.contains(.disableButton) {
                    isDisabled = true
                }

                Task {
                    var progressViewTask: Task<Void, Error>?

                    if actionOptions.contains(.showProgressView) {
                        progressViewTask = Task {
                            try await Task.sleep(nanoseconds: 150_000_000)
                            showProgressView = true
                        }
                    }

                    await action()
                    progressViewTask?.cancel()

                    isDisabled = false
                    showProgressView = false
                }
            },
            label: {
                ZStack {
                    label().opacity(showProgressView ? 0 : 1)

                    if showProgressView {
                        ProgressView()
                    }
                }
            }
        )
        .disabled(isDisabled)
    }
}

extension AsyncButton {
    /// The default options changing the button while waiting for the triggered action.
    enum ActionOption: CaseIterable {
        case disableButton
        case showProgressView
    }
}

extension AsyncButton where Label == Text {
    /// Create a new button with a text label.
    init(_ label: String,
         actionOptions: Set<ActionOption> = Set(ActionOption.allCases),
         action: @escaping () async -> Void) {
        self.init(action: action) {
            Text(label)
        }
    }
}

extension AsyncButton where Label == Image {
    /// Create a new button with an image for the label.
    init(systemImageName: String,
         actionOptions: Set<ActionOption> = Set(ActionOption.allCases),
         action: @escaping () async -> Void) {
        self.init(action: action) {
            Image(systemName: systemImageName)
        }
    }
}

struct AsyncButton_Previews: PreviewProvider {
    static var previews: some View {
        AsyncButton("Button") {

        }
    }
}
