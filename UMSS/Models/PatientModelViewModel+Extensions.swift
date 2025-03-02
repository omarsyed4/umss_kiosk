//
//  PatientModelViewModel+Extensions.swift
//  UMSS
//
//  Created by Omar Syed
//

import Foundation
import UIKit
import FirebaseFirestore


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
    
    // Method to fetch patient data from Firestore
    func fetchPatientData(patientId: String, completion: @escaping (Bool) -> Void) {
        let db = Firestore.firestore()
        
        print("Fetching patient data for ID: \(patientId)")
        
        db.collection("patients").document(patientId).getDocument { [weak self] (document, error) in
            guard let self = self else {
                completion(false)
                return
            }
            
            if let error = error {
                print("Error fetching patient data: \(error.localizedDescription)")
                completion(false)
                return
            }
            
            guard let document = document, document.exists, let data = document.data() else {
                print("Patient document does not exist or has no data")
                completion(false)
                return
            }
            
            DispatchQueue.main.async {
                // Basic info
                self.patientModel.firstName = data["firstName"] as? String ?? ""
                self.patientModel.lastName = data["lastName"] as? String ?? ""
                self.patientModel.email = data["email"] as? String ?? ""
                self.patientModel.dob = data["dob"] as? String ?? ""
                
                // Convert DOB string to Date if available
                if let dobString = data["dob"] as? String, !dobString.isEmpty {
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "MM/dd/yyyy"
                    if let dobDate = dateFormatter.date(from: dobString) {
                        self.patientModel.dateOfBirth = dobDate
                    }
                }
                
                self.patientModel.age = data["age"] as? String ?? ""
                self.patientModel.phone = data["phone"] as? String ?? ""
                self.patientModel.reasonForVisit = data["reason"] as? String ?? ""
                self.patientModel.isExistingPatient = data["isExistingPatient"] as? Bool ?? false
                
                // Demographics
                self.patientModel.selectedGender = data["gender"] as? String ?? ""
                self.patientModel.isMale = self.patientModel.selectedGender == "Male"
                self.patientModel.isFemale = self.patientModel.selectedGender == "Female"
                
                self.patientModel.selectedRace = data["race"] as? String ?? ""
                self.patientModel.isWhite = self.patientModel.selectedRace == "White"
                self.patientModel.isBlack = self.patientModel.selectedRace == "Black / African American" 
                self.patientModel.isAsian = self.patientModel.selectedRace == "Asian"
                self.patientModel.isAmIndian = self.patientModel.selectedRace == "American Indian"
                
                self.patientModel.selectedMaritalStatus = data["maritalStatus"] as? String ?? ""
                self.patientModel.isSingle = self.patientModel.selectedMaritalStatus == "Single"
                self.patientModel.isMarried = self.patientModel.selectedMaritalStatus == "Married"
                self.patientModel.isDivorced = self.patientModel.selectedMaritalStatus == "Divorced"
                self.patientModel.isWidowed = self.patientModel.selectedMaritalStatus == "Widowed"
                
                self.patientModel.selectedEthnicity = data["ethnicity"] as? String ?? ""
                self.patientModel.isHispanic = self.patientModel.selectedEthnicity == "Hispanic/Latino"
                self.patientModel.isNonHispanic = self.patientModel.selectedEthnicity == "Not Hispanic/Latino"
                
                self.patientModel.selectedIncome = data["income"] as? String ?? ""
                self.patientModel.selectedFamilySize = data["familySize"] as? String ?? ""
                self.patientModel.selectedIncomeThreshold = data["incomeThreshold"] as? String ?? ""
                
                // Address information
                self.patientModel.rawAddress = data["rawAddress"] as? String ?? ""
                self.patientModel.address = data["address"] as? String ?? ""
                self.patientModel.city = data["city"] as? String ?? ""
                self.patientModel.state = data["state"] as? String ?? ""
                self.patientModel.zip = data["zip"] as? String ?? ""
                self.patientModel.cityStateZip = data["cityStateZip"] as? String ?? ""
                
                print("Successfully loaded patient data for ID: \(patientId)")
                completion(true)
            }
        }
    }
}
