//
//  BC_Flight_ShareApp.swift
//  BC Flight Share
//
//  Created by Alex Dardarian on 5/27/26.
//

import SwiftUI
import FirebaseCore

@main
struct BC_Flight_ShareApp: App {
    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
