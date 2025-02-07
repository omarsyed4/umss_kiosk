//
//  PatientForm.swift
//  UMSS
//
//  Created by Omar Syed on 1/29/25.
//

import SwiftUI

/// Model struct that holds the user's input data
struct PatientForm {
    // Existing fields
    var email: String = ""
    var firstName: String = ""
    var lastName: String = ""
    
    // Computed property that combines first & last.
    var fullName: String {
        let combined = "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
        return combined
    }
    
    var dob: String = ""
    var phone: String = ""
    var rawAddress: String = ""
    var address: String = ""
    var cityStateZip: String = ""
    
    // Gender checkboxes
    var selectedGender: String = ""
    var isMale: Bool = false
    var isFemale: Bool = false

    // Race checkboxes
    var isWhite: Bool = false
    var isBlack: Bool = false
    var isAsian: Bool = false
    var isAmIndian: Bool = false
    
    // Ethnicity checkboxes
    var isHispanic: Bool = false
    var isNonHispanic: Bool = false
    
    // Additional fields
    var date: String = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yyyy"  // Change format if needed
        return formatter.string(from: Date())
    }()
    var signatureImage: UIImage? = nil
}
