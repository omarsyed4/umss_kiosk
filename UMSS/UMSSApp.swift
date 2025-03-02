//
//  UMSSApp.swift
//  UMSS
//
//  Created by Omar Syed on 1/29/25.
//

import SwiftUI
import Firebase
import GooglePlaces

@main
struct UMSSApp: App {
    
    // Initialize Firebase and Google Places SDK when the app starts
    init() {
        FirebaseApp.configure()
        
        // Initialize Google Places SDK with your API key
        GMSPlacesClient.provideAPIKey("AIzaSyDjjjqcvAGEasl94fn7x2yEUM9M4QP06Mg")
        
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
