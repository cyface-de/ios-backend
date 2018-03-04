//
//  ReachabilityManager.swift
//  DataCapturing
//
//  Created by Team Cyface on 18.01.18.
//

import Foundation
import Reachability

public class ReachabilityManager: NSObject {
    var isNetworkAvailable: Bool {
        return reachabilityStatus != .none
    }

    var reachabilityStatus: Reachability.Connection = .none

    let reachability = Reachability()!

    var noNetworkHandler: (() -> Void)?
    var cellularNetworkHandler: (() -> Void)?
    var wiFiNetworkHandler: (() -> Void)?

    @objc func reachabilityChanged(notification: Notification) {
        let reachability = notification.object as! Reachability

        switch reachability.connection {
        case.none:
            debugPrint("No network connection.")
            if let noNetworkHandler = noNetworkHandler {
                noNetworkHandler()
            }
        case .cellular:
            debugPrint("Cellular network connection.")
            if let cellularNetworkHandler = cellularNetworkHandler {
                cellularNetworkHandler()
            }
        case .wifi:
            debugPrint("WiFi network connection.")
            if let wiFiNetworkHandler = wiFiNetworkHandler {
                wiFiNetworkHandler()
            }
        }
    }

    public func startMonitoring(
        onNoNetwork noNetworkHandler: (() -> Void)?,
        onCellularNetwork cellularNetworkHandler: (() -> Void)?,
        onWiFiNetwork wiFiNetworkHandler: (() -> Void)?) {
        
        self.noNetworkHandler = noNetworkHandler
        self.cellularNetworkHandler = cellularNetworkHandler
        self.wiFiNetworkHandler = wiFiNetworkHandler

        NotificationCenter.default.addObserver(self,
                                selector: #selector(self.reachabilityChanged),
                                name: Notification.Name.reachabilityChanged,
                                object: reachability)

        do {
            try reachability.startNotifier()
        } catch {
            debugPrint("Unable to start reachability notifier!")
        }
    }

    public func stopMonitoring() {
        reachability.stopNotifier()
        NotificationCenter.default.removeObserver(self,
                                        name: Notification.Name.reachabilityChanged,
                                        object: reachability)
        noNetworkHandler = nil
        cellularNetworkHandler = nil
        wiFiNetworkHandler = nil
    }
}
