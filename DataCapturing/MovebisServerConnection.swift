//
//  MovebisServerConnection.swift
//  DataCapturing
//
//  Created by Team Cyface on 23.02.18.
//

import Foundation
import Alamofire

class MovebisServerConnection {
    
    private var jwtAuthenticationToken: String?
    private lazy var serializer = CyfaceBinaryFormatSerializer()
    
    var installationIdentifier:String {
        return "garbage"
    }
    
    init() {
        let serverTrustPolicies: [String: ServerTrustPolicy] = [
            "test.example.com": .pinCertificates(
                certificates: ServerTrustPolicy.certificates(),
                validateCertificateChain: true,
                validateHost: true
            ),
            "insecure.expired-apis.com": .disableEvaluation
        ]
        
        let sessionManager = SessionManager(
            serverTrustPolicyManager: ServerTrustPolicyManager(policies: serverTrustPolicies)
        )
    }
    
    public func authenticate(withJwtToken token: String) {
        jwtAuthenticationToken = token
    }
    
    public func sync(measurement: MeasurementMO, onFinish handler: @escaping (ServerConnectionError?) -> ()) {
        let url = "https://localhost:8080"
        
        guard let jwtAuthenticationToken = jwtAuthenticationToken else {
            fatalError("MovebisServerConnection.sync(measurement:\(measurement.identifier)): Unable to sync. No authentication information provided.")
        }
        
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(jwtAuthenticationToken)",
            "Content-type": "multipart/form-data"
        ]
        
        Alamofire.upload(multipartFormData: { (multipartFormData) in
                multipartFormData.append(self.installationIdentifier.data(using: String.Encoding.utf8)!, withName: "deviceId")
                multipartFormData.append(String(measurement.identifier).data(using: String.Encoding.utf8)!, withName: "measurementId")
            
            let payload = self.serializer.serialize(measurement)
            multipartFormData.append(payload, withName: "fileToUpload", fileName: "\(self.installationIdentifier)_\(measurement.identifier).cyf", mimeType: "application/octet-stream")
        }, usingThreshold: UInt64.init(), to: url, method: .post, headers: headers) { result in
            switch result {
            case .success(let upload, _, _):
                print("success")
                handler(nil)
            case .failure(let error):
                print("failure")
                handler(ServerConnectionError(title: "Upload error", description: "MovebisServerConnection.sync(\(measurement.identifier)): Unable to upload data \(error.localizedDescription).", code: ))
            }
        }
    }
}
