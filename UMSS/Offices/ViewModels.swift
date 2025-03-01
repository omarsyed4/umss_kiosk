//
//  ViewModels.swift
//  UMSS
//
//  Created by Omar Syed
//

import Foundation
import SwiftUI
import FirebaseFirestore

// Office ViewModel
class OfficeViewModel: ObservableObject {
    @Published var offices: [Office] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var db = Firestore.firestore()
    
    func fetchOffices() {
        isLoading = true
        errorMessage = nil
        
        print("Fetching offices from Firestore...")
        
        db.collection("offices").getDocuments { [weak self] (snapshot, error) in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let error = error {
                    self.errorMessage = "Failed to fetch offices: \(error.localizedDescription)"
                    print("Firestore error: \(error.localizedDescription)")
                    return
                }
                
                guard let snapshot = snapshot else {
                    self.errorMessage = "No snapshot returned"
                    print("No snapshot returned from Firestore")
                    return
                }
                
                print("Firestore returned \(snapshot.documents.count) documents")
                
                if snapshot.documents.isEmpty {
                    self.errorMessage = "No office documents found"
                    print("Firestore returned empty documents array")
                    return
                }
                
                // Debug: Print document data
                for doc in snapshot.documents {
                    print("Document ID: \(doc.documentID), Data: \(doc.data())")
                }
                
                // Modified to work without FirebaseFirestoreSwift
                self.offices = snapshot.documents.compactMap { document in
                    let data = document.data()
                    guard let name = data["name"] as? String,
                          let address = data["address"] as? String,
                          let phone = data["phone"] as? String else {
                        print("Error parsing document \(document.documentID): missing required fields")
                        return nil
                    }
                    
                    var office = Office(id: document.documentID, name: name, address: address, phone: phone)
                    return office
                }
                
                print("Successfully decoded \(self.offices.count) offices")
                
                // If we parsed 0 offices but had documents, there's a decoding issue
                if self.offices.isEmpty && !snapshot.documents.isEmpty {
                    self.errorMessage = "Error parsing office data"
                }
            }
        }
    }
}

// Appointments ViewModel
class AppointmentViewModel: ObservableObject {
    @Published var isLoading = true
    @Published var errorMessage: String?
    @Published var todaysOffice: Office?
    @Published var appointments: [Appointment] = []
    @Published var isClinicDay = false
    @Published var selectedOfficeId: String?
    
    private var db = Firestore.firestore()
    
    func checkForTodayClinic() {
        isLoading = true
        errorMessage = nil
        
        // Format today's date as m-d-yy
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "M-d-yy"
        let todayString = dateFormatter.string(from: Date())
        
        print("Checking if today (\(todayString)) is a clinic day...")
        
        // Query the days collection for today's date
        db.collection("days").document(todayString).getDocument { [weak self] (document, error) in
            guard let self = self else { return }
            
            if let error = error {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = "Error checking clinic day: \(error.localizedDescription)"
                    print("Firestore error: \(error.localizedDescription)")
                }
                return
            }
            
            guard let document = document, document.exists else {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.isClinicDay = false
                    print("Today is not a clinic day")
                }
                return
            }
            
            // Today is a clinic day
            guard let data = document.data(), let officeId = data["officeId"] as? String else {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = "Invalid day document format"
                    print("Day document doesn't contain officeId")
                }
                return
            }
            
            print("Today is a clinic day at office ID: \(officeId)")
            self.selectedOfficeId = officeId
            self.isClinicDay = true
            
            // Now fetch the office and its appointments
            self.fetchOfficeAndAppointments(officeId: officeId)
        }
    }
    
    private func fetchOfficeAndAppointments(officeId: String) {
        // First, get the office details
        db.collection("offices").document(officeId).getDocument { [weak self] (document, error) in
            guard let self = self else { return }
            
            if let error = error {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = "Error fetching office: \(error.localizedDescription)"
                }
                return
            }
            
            guard let document = document, document.exists else {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = "Office not found"
                }
                return
            }
            
            // Parse office data
            let data = document.data() ?? [:]
            let office = Office(
                id: document.documentID,
                name: data["name"] as? String ?? "Unknown Office",
                address: data["address"] as? String ?? "No Address",
                phone: data["phone"] as? String ?? "No Phone"
            )
            
            // Now fetch the appointments
            self.fetchAppointments(officeId: officeId, office: office)
        }
    }
    
    private func fetchAppointments(officeId: String, office: Office) {
        db.collection("offices").document(officeId).collection("appointments")
            .getDocuments { [weak self] (snapshot, error) in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    self.isLoading = false
                    
                    if let error = error {
                        self.errorMessage = "Error fetching appointments: \(error.localizedDescription)"
                        return
                    }
                    
                    guard let snapshot = snapshot else {
                        self.errorMessage = "No appointments data"
                        return
                    }
                    
                    // Process appointments
                    self.appointments = snapshot.documents.compactMap { doc in
                        let data = doc.data()
                        return Appointment(
                            id: doc.documentID,
                            time: data["dateTime"] as? String ?? "Unknown Time",
                            patientName: data["patientName"] as? String,
                            status: data["status"] as? String ?? "Available",
                            notes: data["notes"] as? String
                        )
                    }
                    
                    // Sort appointments by time
                    self.appointments.sort { $0.time < $1.time }
                    
                    self.todaysOffice = office
                    print("Fetched \(self.appointments.count) appointments for \(office.name)")
                }
            }
    }
}
