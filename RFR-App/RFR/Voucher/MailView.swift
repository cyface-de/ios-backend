/*
 * Copyright 2024 Cyface GmbH
 *
 * This file is part of the Ready for Robots iOS App.
 *
 * The Ready for Robots iOS App is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * The Ready for Robots iOS App is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with the Ready for Robots iOS App. If not, see <http://www.gnu.org/licenses/>.
 */
import SwiftUI
import UIKit
import MessageUI

/// The type of callbacks used when calling the systems E-Mail application
typealias MailViewCallback = ((Result<MFMailComposeResult, Error>) -> Void)?

/**
 The view showng when the user wants to send its voucher via E-Mail.

 Since this is currently not supported by SwiftUI, it is implemented as a UIViewController using `UIViewControllerRepresentable`.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 - Since: 3.2.2
 */
struct MailView: UIViewControllerRepresentable {

    /// Specifies whether to show this view or not.
    @Environment(\.presentationMode) var presentation
    /// The data of the mail to send.
    var data: ComposeMailData
    /// Called when the mail was sent.
    let callback: MailViewCallback

    /**
     The UIKit Coordinator for this representable.

     - Author: Klemens Muthmann
     - Version: 1.0.0
     - Since: 3.2.2
     */
    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        @Binding var presentation: PresentationMode
        var data: ComposeMailData
        let callback: MailViewCallback

        init(presentation: Binding<PresentationMode>,
             data: ComposeMailData,
             callback: MailViewCallback) {
            _presentation = presentation
            self.data = data
            self.callback = callback
        }

        func mailComposeController(_ controller: MFMailComposeViewController,
                                   didFinishWith result: MFMailComposeResult,
                                   error: Error?) {
            if let error = error {
                callback?(.failure(error))
            } else {
                callback?(.success(result))
            }
            $presentation.wrappedValue.dismiss()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(presentation: presentation, data: data, callback: callback)
    }

    func makeUIViewController(context: UIViewControllerRepresentableContext<MailView>) -> MFMailComposeViewController {
        let vc = MFMailComposeViewController()
        vc.mailComposeDelegate = context.coordinator
        vc.setSubject(data.subject)
        vc.setToRecipients(data.recipients)
        vc.setMessageBody(data.message, isHTML: false)
        data.attachments?.forEach {
            vc.addAttachmentData($0.data, mimeType: $0.mimeType, fileName: $0.fileName)
        }
        vc.accessibilityElementDidLoseFocus()
        return vc
    }

    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: UIViewControllerRepresentableContext<MailView>) {
    }

    /// `true` if mail sending is allowed, `false` otherwise.
    static var canSendMail: Bool {
        MFMailComposeViewController.canSendMail()
    }
}

/**
 The data used to create the mail

 - Author: Klemens Muthmann
 - Version: 1.0.0
 - Since: 3.2.2
 */
struct ComposeMailData {
    let subject: String
    let recipients: [String]?
    let message: String
    let attachments: [AttachmentData]?
}

/**
 Data attached to the E-Mail.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 - Since: 3.2.2
 */
struct AttachmentData {
    let data: Data
    let mimeType: String
    let fileName: String
}
