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
    var age: String = ""
    var phone: String = ""
    var rawAddress: String = ""
    var address: String = ""
    var city: String = ""
    var state: String = ""
    var zip: String = ""
    var cityState: String = ""
    var cityStateZip: String = ""
    
    var isExistingPatient: Bool = false

    // Gender properties
    var selectedGender: String = ""
    var isMale: Bool = false
    var isFemale: Bool = false
    
    var selectedIncome: String = ""
    var selectedFamilySize = ""
    var selectedIncomeThreshold = ""
    
    // Marital status checkboxes
    var isSingle: Bool = false
    var isMarried: Bool = false
    var isDivorced: Bool = false
    var isWidowed: Bool = false

    // Race checkboxes
    var isWhite: Bool = false
    var isBlack: Bool = false
    var isAsian: Bool = false
    var isAmIndian: Bool = false
    
    var selectedRace: String = ""
    var selectedMaritalStatus: String = ""
    var selectedEthnicity: String = ""

    // Ethnicity checkboxes
    var isHispanic: Bool = false
    var isNonHispanic: Bool = false
    
    // Insurance checkbox (default to "False")
    var insuredNo: Bool = false
    
    var reasonForVisit: String = ""
    
    // Additional fields
    var date: String = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yyyy"  // Change format if needed
        return formatter.string(from: Date())
    }()
    var signatureImage: UIImage? = nil

    // MARK: - Computed Properties for Readable Strings

    /// Returns the gender as a string. (e.g., "Male" or "Female")
    var genderString: String {
        return selectedGender
    }

    /// Returns the race as a comma-separated string.
    var raceString: String {
        var races = [String]()
        if isWhite { races.append("White") }
        if isBlack { races.append("Black/African American") }
        if isAsian { races.append("Asian") }
        if isAmIndian { races.append("American Indian") }
        return races.joined(separator: ", ")
    }

    /// Returns the ethnicity as a string.
    var ethnicityString: String {
        // If both ethnicity toggles are on, you may choose to return a combination or handle it as an error.
        if isHispanic && !isNonHispanic {
            return "Hispanic/Latino"
        } else if !isHispanic && isNonHispanic {
            return "Not Hispanic/Latino"
        } else if isHispanic && isNonHispanic {
            // This could be handled differently based on your app's logic.
            return "Hispanic/Latino, Not Hispanic/Latino"
        } else {
            return ""
        }
    }
}
