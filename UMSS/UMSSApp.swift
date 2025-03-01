//
//  UMSSApp.swift
//  UMSS
//
//  Created by Omar Syed on 1/29/25.
//

import SwiftUI
import Firebase

@main
struct UMSSApp: App {
    
    // Initialize Firebase when the app starts
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
