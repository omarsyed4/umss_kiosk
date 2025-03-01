//
//  PatientModel+Extensions.swift
//  UMSS
//
//  Created by Omar Syed
//

import Foundation
import UIKit

// Add properties needed for appointment integration
extension PatientModel {
    // Store the selected appointment ID
    var appointmentId: String {
        get {
            return UserDefaults.standard.string(forKey: "patientAppointmentId") ?? ""
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "patientAppointmentId")
        }
    }
}
