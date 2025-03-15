//
//  PatientModel.swift
//  UMSS
//
//  Created by Omar Syed on 1/29/25.
//

import SwiftUI
import Foundation
import UIKit

/// Model struct that holds the user's input data
class PatientModel: ObservableObject {
    // Basic Information
    @Published var email: String = ""
    @Published var firstName: String = ""
    @Published var lastName: String = ""
    @Published var dob: String = ""  // String representation
    @Published var dateOfBirth: Date = Date()  // Date object for the datepicker
    @Published var age: String = ""
    @Published var phone: String = ""
    @Published var rawAddress: String = ""
    @Published var address: String = ""
    @Published var city: String = ""
    @Published var state: String = ""
    @Published var zip: String = ""
    @Published var cityState: String = ""
    @Published var cityStateZip: String = ""
    @Published var reasonForVisit: String = ""
    @Published var isExistingPatient: Bool = false

    // Gender properties
    @Published var selectedGender: String = ""
    @Published var isMale: Bool = false
    @Published var isFemale: Bool = false
    
    @Published var selectedIncome: String = ""
    @Published var selectedFamilySize = ""
    @Published var selectedIncomeThreshold = ""
    
    // Marital status checkboxes
    @Published var isSingle: Bool = false
    @Published var isMarried: Bool = false
    @Published var isDivorced: Bool = false
    @Published var isWidowed: Bool = false

    // Race checkboxes
    @Published var isWhite: Bool = false
    @Published var isBlack: Bool = false
    @Published var isAsian: Bool = false
    @Published var isAmIndian: Bool = false
    
    @Published var selectedRace: String = ""
    @Published var selectedMaritalStatus: String = ""
    @Published var selectedEthnicity: String = ""

    // Ethnicity checkboxes
    @Published var isHispanic: Bool = false
    @Published var isNonHispanic: Bool = false
    
    // Insurance checkbox (default to "False")
    @Published var insuredNo: Bool = false
    
    // Additional fields
    @Published var date: String = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yyyy"  // Change format if needed
        return formatter.string(from: Date())
    }()
    @Published var signatureImage: UIImage? = nil

    // Office selection
    @Published var selectedOfficeId: String?
    @Published var selectedOfficeName: String = ""
    @Published var selectedOfficeAddress: String = ""
    @Published var selectedOfficePhone: String = ""
    
    @Published var height: Int = 0
    @Published var weight: Int = 0
    @Published var temperature: Double = 0
    @Published var heartRate: Int = 0
    @Published var painLevel: Int = 0

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

    /// Returns the full name as a string.
    var fullName: String {
        return "\(firstName) \(lastName)"
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
