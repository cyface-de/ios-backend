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
import DataCapturing
import SwiftUI
import MessageUI

/**
 View model used for the view showing the voucher.

 - Author: Klemens Muthmann
 - Version: 2.0.0
 - Since: 3.1.2
 */
class VoucherViewModel: ObservableObject {
    // MARK: - Private Properties
    /// A retrieved voucher is stored to user defaults under this key.
    private static let userDefaultsKey = "de.cyface.rfr.voucher"
    // MARK: - Properties
    /// The acquired voucher or `nil` if no voucher has been acquired yet.
    @Published var voucher: Voucher?
    /// The number of available fouchers, shown as long as the current user did not acquire a voucher already.
    @Published var voucherCount: Int = 0
    /// `true` if the view to send the acquired voucher via E-Mail should display; `false` otherwise.
    @Published var showMailView: Bool = false
    /// The information making up an E-Mail.
    @Published var mailData: ComposeMailData?
    /// A handle to the `Vouchers` API, for retrieving voucher information from the server.
    private let vouchers: Vouchers
    /// An algorithm to calculate whether a user is eligleble for a voucher or not.
    private var voucherRequirements: VoucherRequirements
    /// `true` if a voucher is redeemable at the moment; `false` if the competition period is over.
    private var voucherRedeemable: Bool {
        var redeemDate = DateComponents()
        redeemDate.year = 2024
        redeemDate.month = 6
        redeemDate.day = 1
        redeemDate.timeZone = TimeZone(abbreviation: "CEST")
        redeemDate.hour = 23
        redeemDate.minute = 59
        redeemDate.second = 59

        return Date.now <= Calendar.current.date(from: redeemDate)!
    }

    // MARK: - Initializers
    /// Create a new object of this class, communicating with the voucher API  via the provided `Vouchers` instance`.
    init(vouchers: Vouchers, voucherRequirements: VoucherRequirements) {
        self.vouchers = vouchers
        self.voucherRequirements = voucherRequirements
        let decoder = JSONDecoder()
        if let voucherData = UserDefaults.standard.data(forKey: VoucherViewModel.userDefaultsKey) {
            DispatchQueue.main.async { [weak self] in
                do {
                    self?.voucher = try decoder.decode(Voucher.self, from: voucherData)
                } catch {
                    fatalError()
                }
            }
        }
    }

    // MARK: - Methods
    /// Handle a press on the 'load vouchers' button, loading a voucher.
    ///
    /// - Throws: If communication with the server fails or no vouchers are available anymore.
    /// Please have a look a the voucher API documentation and ``VoucherRequestError`` to get information about the meaning of the different HTTP Status codes returned.
    func onPressLoadVoucherButton() async throws {
        let voucher = try await vouchers.requestVoucher()

        let encoder = JSONEncoder()
        let data = try encoder.encode(voucher)
        UserDefaults.standard.set(data, forKey: VoucherViewModel.userDefaultsKey)
        UserDefaults.standard.synchronize()
        DispatchQueue.main.async {
            self.voucher = voucher
        }
    }

    // The following send E-Mail functionality is based on code from the following StackOverflowThread: https://stackoverflow.com/questions/25981422/how-to-open-mail-app-from-swift
    /// This function is called if the user presses the send E-Mail button.
    func onSendEMailButtonPressed() {
        guard let voucher = voucher else {
            return
        }

        // Modify following variables with your text / recipient
        let recipientEmail = "gewinnspiel@ready-for-robots.de"
        let subject = String(format: NSLocalizedString("de.cyface.rfr.label.VoucherViewModel.mail_subject", comment: "The subject of the participation E-Mail when sending a voucher."), voucher.code) //"Gewinnlos: \(voucher.code)"
        let body = ""

        if MFMailComposeViewController.canSendMail() {
            mailData = ComposeMailData(subject: subject, recipients: [recipientEmail], message: body, attachments: [])
            self.showMailView.toggle()
        } else if let emailUrl = createEmailUrl(to: recipientEmail, subject: subject, body: body) {
            UIApplication.shared.open(emailUrl)
        }
    }

    /// Create a URL to send the E-Mail if the native mail application is not available.
    ///
    /// This tries to start GMail, Outlook, YahooMail, Spark or the default program registered for the mailto scheme.
    private func createEmailUrl(to: String, subject: String, body: String) -> URL? {
        let subjectEncoded = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        let bodyEncoded = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!

        let gmailUrl = URL(string: "googlegmail://co?to=\(to)&subject=\(subjectEncoded)&body=\(bodyEncoded)")
        let outlookUrl = URL(string: "ms-outlook://compose?to=\(to)&subject=\(subjectEncoded)&body=\(bodyEncoded)")
        let yahooMail = URL(string: "ymail://mail/compose?to=\(to)&subject=\(subjectEncoded)&body=\(bodyEncoded)")
        let sparkUrl = URL(string: "readdle-spark://compose?recipient=\(to)&subject=\(subjectEncoded)&body=\(bodyEncoded)")
        let defaultUrl = URL(string: "mailto:\(to)?subject=\(subjectEncoded)&body=\(bodyEncoded)")

        if let gmailUrl = gmailUrl, UIApplication.shared.canOpenURL(gmailUrl) {
            return gmailUrl
        } else if let outlookUrl = outlookUrl, UIApplication.shared.canOpenURL(outlookUrl) {
            return outlookUrl
        } else if let yahooMail = yahooMail, UIApplication.shared.canOpenURL(yahooMail) {
            return yahooMail
        } else if let sparkUrl = sparkUrl, UIApplication.shared.canOpenURL(sparkUrl) {
            return sparkUrl
        }

        return defaultUrl
    }

    /// Refresh the state from user defaults and the local database.
    ///
    /// - Throws: If the local storage was not available.
    /// If this happens something is seriously wrong with the app installation.
    /// It is usually not possible to recover from such an error.
    @MainActor
    func refreshModel() async throws {
        if voucherRequirements.isQualifiedForVoucher() {
            if let data = UserDefaults.standard.data(forKey: VoucherViewModel.userDefaultsKey) {
                let decoder = JSONDecoder()
                voucher = try? decoder.decode(Voucher.self, from: data)
            }
        } else {
            try await voucherRequirements.refreshProgress()
        }

        Task {
            self.voucherCount = (try? await vouchers.count) ?? 0
        }
    }

    /// Create the correct view for the current progress in acquiring a voucher.
    /// At first show the amount of vouchers available and the progress towards acquiring one.
    /// Thereafter show a button to acquire a voucher and finally show the voucher itself if one was still available.
    @ViewBuilder
    func view() -> some View {
        if !thereIsCurrentEvent() {
          NoVoucher(voucherRedeemable: voucherRedeemable)
        } else if voucherCount > 0 && !voucherRequirements.isQualifiedForVoucher() {
            voucherRequirements.progressView(voucherCount: voucherCount).padding([.top, .bottom])
        } else if voucherCount > 0 && voucherRequirements.isQualifiedForVoucher() && voucher == nil {
            VoucherReached(viewModel: self).padding([.top, .bottom])
        } else if voucherCount == 0 && voucher == nil {
            NoVoucher(voucherRedeemable: voucherRedeemable).padding([.top, .bottom])
        } else if voucher != nil && voucherRedeemable {
            VoucherEnabled(viewModel: self).padding([.top, .bottom])
        } else {
            EmptyView()
        }
    }
}
