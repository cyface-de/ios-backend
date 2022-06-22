//
//  Credentials.swift
//  Cyface-App
//
//  Created by Klemens Muthmann on 28.03.22.
//

import Foundation
import DataCapturing

struct Credentials {
    var username: String
    var password: String

    func login(onSuccess: ()->(), onFailure: (Error)->()) {
        onSuccess()
    }
}
