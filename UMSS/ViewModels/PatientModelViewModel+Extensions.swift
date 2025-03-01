//
//  PatientModelViewModel+Extensions.swift
//  UMSS
//
//  Created by Omar Syed
//

import Foundation
import UIKit

extension PatientModelViewModel {
    // Method to reset all patient data fields
    func resetPatientData() {
        // Reset basic info
        patientModel.email = ""
        patientModel.firstName = ""
        patientModel.lastName = ""
        patientModel.dob = ""
        patientModel.age = ""
        patientModel.phone = ""
        patientModel.reasonForVisit = ""
        patientModel.isExistingPatient = false
        
        // Reset demographics
        patientModel.selectedGender = ""
        patientModel.selectedRace = ""
        patientModel.selectedMaritalStatus = ""
        patientModel.selectedEthnicity = ""
        patientModel.selectedIncome = ""
        patientModel.address = ""
        
        // Reset signature and address details
        patientModel.signatureImage = nil
        patientModel.rawAddress = ""
        patientModel.city = ""
        patientModel.state = ""
        patientModel.zip = ""
        patientModel.cityStateZip = ""
        
        // Reset additional demographic booleans/values
        patientModel.isMale = false
        patientModel.isFemale = false
        patientModel.isWhite = false
        patientModel.isBlack = false
        patientModel.isAsian = false
        patientModel.isAmIndian = false
        patientModel.isHispanic = false
        patientModel.isNonHispanic = false
        patientModel.isSingle = false
        patientModel.isMarried = false
        patientModel.isDivorced = false
        patientModel.isWidowed = false
        patientModel.selectedFamilySize = ""
        patientModel.selectedIncomeThreshold = ""
        
        // Keep the appointmentId - we don't reset this since it's what links
        // the patient to their selected appointment time
    }
}
