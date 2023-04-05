//
//  Preview_Mocks.swift
//  RFR
//
//  Created by Klemens Muthmann on 03.04.23.
//
#if DEBUG
import Foundation
import DataCapturing

class MockDataCapturingService: DataCapturingService {
    var isRunning: Bool
    
    var isPaused: Bool
    
    var currentMeasurement: Int64?
    
    var capturedMeasurement: DataCapturing.Measurement?
    
    var handler: [((DataCapturing.DataCapturingEvent, DataCapturing.Status) -> Void)]
    
    init(state: MeasurementState) {
        self.currentMeasurement = nil
        self.capturedMeasurement = nil
        self.handler = [((DataCapturing.DataCapturingEvent, DataCapturing.Status) -> Void)]()
        
        switch state {
        case .paused:
            isRunning = false
            isPaused = true
        case .running:
            isRunning = true
            isPaused = false
        case .stopped:
            isRunning = false
            isPaused = false
        }
    }
    
    func setup() {
        
    }
    
    func start(inMode modality: String) throws {
        
    }
    
    func stop() throws {
        
    }
    
    func pause() throws {
        
    }
    
    func resume() throws {
        
    }
    
    func changeModality(to modality: String) {
        
    }
}

class MockAuthenticator: CredentialsAuthenticator {
    var username: String?
    
    var password: String?
    
    var authenticationEndpoint: URL
    
    init() {
        self.username = ""
        self.password = ""
        self.authenticationEndpoint = URL(string: "http://localhost")!
    }
    
    func authenticate(onSuccess: @escaping (String) -> Void, onFailure: @escaping (Error) -> Void) {
        
    }
    
    func authenticate() async throws -> String {
        return "test"
    }
}

#endif
