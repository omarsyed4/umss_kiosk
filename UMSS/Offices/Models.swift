//
//  Models.swift
//  UMSS
//
//  Created by Omar Syed
//

import Foundation
import FirebaseFirestore

// Office Model
struct Office: Identifiable, Codable {
    var id: String?
    let name: String
    let address: String
    let phone: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case address
        case phone
    }
}

// Models for the appointments feature
struct AppointmentDay {
    var id: String
    var date: String
    var officeId: String
}

struct Appointment: Identifiable {
    var id: String
    var time: String
    var date: String
    var patientId: String
    var booked: String
    var isCheckedIn: String
    var seenDoctor: String
    var vitalsDone: String?
    
    // Computed properties for compatibility
    var status: String {
        if booked == "true" {
            return "Booked"
        } else {
            return "Available"
        }
    }
    
    var patientName: String? {
        return patientId.isEmpty ? nil : patientId
    }
    
    var notes: String? {
        var noteComponents = [String]()
        
        if isCheckedIn == "true" {
            noteComponents.append("Checked In")
        }
        
        if seenDoctor == "true" {
            noteComponents.append("Seen Doctor")
        }
        
        if let vitals = vitalsDone, vitals == "true" {
            noteComponents.append("Vitals Done")
        }
        
        return noteComponents.isEmpty ? nil : noteComponents.joined(separator: ", ")
    }
}
