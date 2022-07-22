//
//  HCaptchaViewModel.swift
//  Cyface-App
//
//  Created by Klemens Muthmann on 21.07.22.
//

import Foundation

class HCaptchaViewModel: ObservableObject {
    @Published var token = ""
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var isValidated = false
    @Published var isLoading = false
}
