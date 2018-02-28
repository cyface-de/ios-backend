//
//  MovebisServerConnection.swift
//  DataCapturing
//
//  Created by Team Cyface on 23.02.18.
//

import Foundation
import Alamofire

public class MovebisServerConnection: ServerConnection {
    
    private var jwtAuthenticationToken: String?
    private lazy var serializer = CyfaceBinaryFormatSerializer()
    private let sessionManager: SessionManager
    private let apiURL: URL
    private var onFinishHandler: ((ServerConnectionError?) -> Void)?
    
    var installationIdentifier:String {
        if let applicationIdentifier = UserDefaults.standard.string(forKey: "de.cyface.identifier") {
            return applicationIdentifier
        } else {
            let applicationIdentifier = UUID.init().uuidString
            UserDefaults.standard.set(applicationIdentifier, forKey: "de.cyface.identifier")
            return applicationIdentifier
        }
    }
    
    public required init(apiURL url: URL) {
        apiURL = url
        
        guard let urlHost = url.host else {
            fatalError("MovebisServerConnection.init(\(url.absoluteString)): Invalid URL! No host specified!")
        }
        
        // TODO: This ignores any certificate issues and is ugly. Should be changed to check for correct certificate.
        let serverTrustPolicies: [String: ServerTrustPolicy] = [
            urlHost: .disableEvaluation
        ]
        
        sessionManager = SessionManager(
            serverTrustPolicyManager: ServerTrustPolicyManager(policies: serverTrustPolicies)
        )
    }
    
    public func authenticate(withJwtToken token: String) {
        jwtAuthenticationToken = token
    }
    
    public func sync(measurement: MeasurementMO, onFinish handler: @escaping (ServerConnectionError?) -> ()) {
        let url = apiURL.appendingPathComponent("measurements")
        onFinishHandler = handler
        
        guard let jwtAuthenticationToken = jwtAuthenticationToken else {
            fatalError("MovebisServerConnection.sync(measurement:\(measurement.identifier)): Unable to sync. No authentication information provided.")
        }
        
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(jwtAuthenticationToken)",
            "Content-type": "multipart/form-data"
        ]
        
        sessionManager.upload(multipartFormData: { (multipartFormData) in
            multipartFormData.append(self.installationIdentifier.data(using: String.Encoding.utf8)!, withName: "deviceId")
            multipartFormData.append(String(measurement.identifier).data(using: String.Encoding.utf8)!, withName: "measurementId")
            
            let payload = self.serializer.serialize(measurement)
            multipartFormData.append(payload, withName: "fileToUpload", fileName: "\(self.installationIdentifier)_\(measurement.identifier).cyf", mimeType: "application/octet-stream")
        }, usingThreshold: UInt64.init(), to: url, method: .post, headers: headers, encodingCompletion: onEncodingComplete)
    }
    
    func onEncodingComplete(withResult result: SessionManager.MultipartFormDataEncodingResult) {
        switch result {
        case .success(let upload, _, _):
            print("Successfully encoded upload \(upload)")
            upload.validate().responseString(completionHandler: onResponseReady)
        case .failure(let error):
            print("failure")
            if let handler = onFinishHandler {
                handler(ServerConnectionError(title: "Upload error", description: "MovebisServerConnection.onEncodingComplete(\(result)): Unable to upload data \(error.localizedDescription).", code: 1))
            }
        }
    }
    
    func onResponseReady(_ response: DataResponse<String>) {
        guard let handler = onFinishHandler else {
            return
        }
        
        switch response.result {
        case .failure(let error):
            handler(ServerConnectionError(title: "Upload error", description: "MovebisServerConnection.onResponseReady(\(response)): Unable to upload data due to error: \(error)", code: 1))
        case .success(_):
            handler(nil)
        }
    }
}
