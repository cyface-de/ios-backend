//
//  DataCapturingEventHandler.swift
//  Cyface-App
//
//  Created by Klemens Muthmann on 01.07.22.
//

import Foundation
import DataCapturing

protocol CyfaceEventHandler {
    func handle(event: DataCapturingEvent, status: Status)
}

