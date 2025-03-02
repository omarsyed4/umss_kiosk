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
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case address
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
    var booked: Bool
    var isCheckedIn: Bool
    var seenDoctor: Bool
    var vitalsDone: Bool?

    var status: String {
        booked ? "Booked" : "Available"
    }

    var patientName: String? {
        return patientId.isEmpty ? nil : patientId
    }

    var notes: String? {
        var noteComponents = [String]()

        if isCheckedIn {
            noteComponents.append("Checked In")
        }
        if seenDoctor {
            noteComponents.append("Seen Doctor")
        }
        if let vitals = vitalsDone, vitals {
            noteComponents.append("Vitals Done")
        }
        return noteComponents.isEmpty ? nil : noteComponents.joined(separator: ", ")
    }
}