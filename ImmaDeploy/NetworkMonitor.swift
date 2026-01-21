//
//  NetworkMonitor.swift
//  ImmaDeploy
//
//  Created by Assistant on 21/01/26.
//

import Foundation
import Network
import Combine

/// Monitors network reachability and exposes it to SwiftUI via `@Published`.
/// Uses `NWPathMonitor` so the app can defer network work until connectivity is available.
final class NetworkMonitor: ObservableObject {
    static let shared = NetworkMonitor()

    @Published private(set) var isReachable: Bool = false

    private let monitor: NWPathMonitor
    private let queue = DispatchQueue(label: "NetworkMonitorQueue")

    private init() {
        self.monitor = NWPathMonitor()
        self.monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isReachable = (path.status == .satisfied)
            }
        }
        self.monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }
}
