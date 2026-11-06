//
//  ValidationRelayApp.swift
//  ValidationRelay
//
//  Created by James Gill on 3/24/24.
//

import SwiftUI

@main
struct ValidationRelayApp: App {
    @StateObject private var relayConnectionManager = RelayConnectionManager()

    init() {
        // Runs before any view reads the stored value.
        MacIdentityStore.setDefaultIfNeeded()
    }

    var body: some Scene {
        WindowGroup {
            ContentView(relayConnectionManager: relayConnectionManager)
        }
    }
}
