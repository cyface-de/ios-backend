//
//  DataCapturingService.swift
//  DataCapturing
//
//  Created by Team Cyface on 06.03.18.
//  Copyright © 2018 Cyface GmbH. All rights reserved.
//

protocol MeasurementLifecycle {
    func onSyncFinished(measurement: MeasurementMO, error: ServerConnectionError?)
}
