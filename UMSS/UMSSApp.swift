//
//  UMSSApp.swift
//  UMSS
//
//  Created by Omar Syed on 1/29/25.
//

import SwiftUI
import GooglePlaces

@main
struct UMSSApp: App {
    
    init() {
        if let filePath = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
           let plist = NSDictionary(contentsOfFile: filePath),
           let apiKey = plist["GoogleAPIKey"] as? String {
            GMSPlacesClient.provideAPIKey(apiKey)
            print("[DEBUG] API Key loaded from Secrets.plist")
        } else {
            print("[ERROR] Could not load API Key from Secrets.plist")
        }
    }

    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
