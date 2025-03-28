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
                          let address = data["address"] as? String else {
                        print("Error parsing document \(document.documentID): missing required fields")
                        return nil
                    }
                    
                    var office = Office(id: document.documentID, name: name, address: address)
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
    @Published var providers: [Provider] = []  // Add this line to store providers
    
    private var db = Firestore.firestore()
    
    func checkForTodayClinic() {
        isLoading = true
        errorMessage = nil
        providers = [] // Reset providers list when checking for clinic day
        
        // Format today's date as M-D-YY for Firestore document query
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "M-d-yy"
        let today = Date()
        let todayString = dateFormatter.string(from: today)
        
        print("Checking if today (\(todayString)) is a clinic day...")
        
        // Query the days collection for documents starting with today's date
        // Format is now M-D-YY-officeId-startTime
        db.collection("days")
            .whereField(FieldPath.documentID(), isGreaterThanOrEqualTo: todayString)
            .whereField(FieldPath.documentID(), isLessThan: todayString + "\u{f8ff}")
            .getDocuments { [weak self] (querySnapshot, error) in
                guard let self = self else { return }
                
                if let error = error {
                    DispatchQueue.main.async {
                        self.isLoading = false
                        self.errorMessage = "Error checking clinic day: \(error.localizedDescription)"
                        print("Firestore error: \(error.localizedDescription)")
                    }
                    return
                }
                
                guard let documents = querySnapshot?.documents, !documents.isEmpty else {
                    DispatchQueue.main.async {
                        self.isLoading = false
                        self.isClinicDay = false
                        print("Today is not a clinic day")
                    }
                    return
                }
                
                // Use the first clinic document found for today
                let document = documents[0]
                print("Found today's clinic document: \(document.documentID)")
                
                // Extract the officeId from the document ID
                // Format: M-D-YY-officeId-startTime
                let docIdComponents = document.documentID.components(separatedBy: "-")
                guard docIdComponents.count >= 4 else {
                    DispatchQueue.main.async {
                        self.isLoading = false
                        self.errorMessage = "Invalid day document format"
                        print("Day document ID doesn't match expected format")
                    }
                    return
                }
                
                // The officeId should be the fourth component (index 3)
                let officeId = docIdComponents[3]
                
                print("Today is a clinic day at office ID: \(officeId)")
                self.selectedOfficeId = officeId
                self.isClinicDay = true
                
                // Extract provider UIDs from the day document
                if let providerUIDs = document.data()["providers"] as? [String] {
                    print("Found providers data in day document: \(providerUIDs)")
                    
                    // Now fetch detailed provider info
                    self.fetchProvidersFromVolunteers(uids: providerUIDs)
                } else {
                    print("No providers field found in day document or it's not in expected format")
                    self.providers = []
                    
                    // Continue with fetching office and appointments
                    self.fetchOfficeAndAppointments(officeId: officeId)
                }
            }
    }
    
    // New method to fetch provider details from volunteers collection
    private func fetchProvidersFromVolunteers(uids: [String]) {
        guard !uids.isEmpty, let officeId = selectedOfficeId else {
            print("No provider UIDs to fetch or no office ID selected")
            self.providers = []
            if let officeId = selectedOfficeId {
                self.fetchOfficeAndAppointments(officeId: officeId)
            } else {
                self.isLoading = false
            }
            return
        }
        
        print("Fetching details for \(uids.count) providers from volunteers collection")
        
        // Create a dispatch group to wait for all provider queries to complete
        let dispatchGroup = DispatchGroup()
        var fetchedProviders: [Provider] = []
        var errors: [String] = []
        
        for uid in uids {
            dispatchGroup.enter()
            
            db.collection("volunteers").document(uid).getDocument { [weak self] document, error in
                defer { dispatchGroup.leave() }
                guard let self = self else { return }
                
                if let error = error {
                    print("Error fetching volunteer \(uid): \(error.localizedDescription)")
                    errors.append("Failed to fetch volunteer \(uid): \(error.localizedDescription)")
                    return
                }
                
                guard let document = document, document.exists else {
                    print("No document found for volunteer \(uid)")
                    errors.append("No document found for volunteer \(uid)")
                    return
                }
                
                let data = document.data() ?? [:]
                print("Volunteer document data for \(uid): \(data)")
                
                // Extract firstName and lastName from volunteer document
                if let firstName = data["firstName"] as? String,
                   let lastName = data["lastName"] as? String {
                    let fullName = "\(firstName) \(lastName)"
                    
                    // Get specialty if available, default to "Provider" if not
                    let specialty = data["specialty"] as? String ?? "Provider"
                    
                    let provider = Provider(
                        id: uid,
                        name: fullName,
                        specialty: specialty
                    )
                    
                    fetchedProviders.append(provider)
                    print("Added provider: \(fullName) with specialty: \(specialty)")
                } else {
                    print("Missing firstName or lastName in volunteer document for \(uid)")
                    errors.append("Missing firstName or lastName in volunteer document for \(uid)")
                }
            }
        }
        
        // When all providers are fetched, update the published providers array
        dispatchGroup.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
            
            self.providers = fetchedProviders
            
            if fetchedProviders.isEmpty && !errors.isEmpty {
                print("Failed to fetch providers: \(errors.joined(separator: "; "))")
                self.errorMessage = "Failed to load providers: \(errors.first ?? "Unknown error")"
            }
            
            print("Fetched \(fetchedProviders.count) providers from volunteers collection")
            
            // Continue with fetching office and appointments
            if let officeId = self.selectedOfficeId {
                self.fetchOfficeAndAppointments(officeId: officeId)
            } else {
                self.isLoading = false
            }
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
                address: data["address"] as? String ?? "No Address"
            )
            
            // Now fetch the appointments
            self.fetchAppointments(officeId: officeId, office: office)
        }
    }
    
    private func fetchAppointments(officeId: String, office: Office) {
        // Get start and end timestamps for today
        let calendar = Calendar.current
        let today = Date()
        
        let startOfDay = calendar.startOfDay(for: today)
        guard let endOfDay = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: today) else {
            self.errorMessage = "Error creating date range"
            self.isLoading = false
            return
        }
        
        let startTimestamp = Timestamp(date: startOfDay)
        let endTimestamp = Timestamp(date: endOfDay)
        
        print("Fetching appointments between \(startOfDay) and \(endOfDay)")
        
        // Query appointments for today only using Firestore query
        db.collection("offices").document(officeId).collection("appointments")
            .whereField("dateTime", isGreaterThanOrEqualTo: startTimestamp)
            .whereField("dateTime", isLessThanOrEqualTo: endTimestamp)
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
                    
                    print("Found \(snapshot.documents.count) appointments for today")
                    
                    // Parse appointment documents
                    self.appointments = snapshot.documents.compactMap { doc -> Appointment? in
                        let data = doc.data()
                        
                        // Read dateTime from Firestore
                        guard let dateTime = data["dateTime"] as? Timestamp else {
                            print("dateTime is nil for document \(doc.documentID)")
                            return nil
                        }
                        
                        let appointmentDate = dateTime.dateValue()
                        
                        // Format date to "yyyy-MM-dd"
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateFormat = "yyyy-MM-dd"
                        let parsedDate = dateFormatter.string(from: appointmentDate)
    
                        // Format time to "HH:mm"
                        let timeFormatter = DateFormatter()
                        timeFormatter.dateFormat = "h:mm a"
                        let parsedTime = timeFormatter.string(from: appointmentDate)
                        
                        // Build the new Appointment
                        return Appointment(
                            id: doc.documentID,
                            time: parsedTime,
                            date: parsedDate,
                            patientId: data["patientId"] as? String ?? "",
                            patientName: data["patientName"] as? String ?? "",
                            booked: data["booked"] as? Bool ?? false,
                            isCheckedIn: data["isCheckedIn"] as? Bool ?? false,
                            seenDoctor: data["seenDoctor"] as? Bool ?? false,
                            vitalsDone: data["vitalsDone"] as? Bool ?? false
                        )
                    }
                    
                    // Sort appointments by time
                    self.appointments.sort { $0.time < $1.time }
                    self.todaysOffice = office
                }
            }
    }
    
    // New method to send patient to doctor
    func sendPatientToDoctor(appointmentId: String, providerId: String, completion: @escaping (Bool) -> Void) {
        guard let officeId = selectedOfficeId else {
            print("No office ID selected for sending patient to doctor")
            completion(false)
            return
        }
        
        // Find the provider's name
        let providerName = providers.first(where: { $0.id == providerId })?.name ?? "Unknown Provider"
        
        print("Sending patient to doctor: \(providerName) (ID: \(providerId))")
        
        let appointmentRef = db.collection("offices")
            .document(officeId)
            .collection("appointments")
            .document(appointmentId)
        
        appointmentRef.updateData([
            "assignedProviderId": providerId,
            "assignedProviderName": providerName,
            "seenDoctor": false,  // They haven't seen the doctor yet, just assigned
            "vitalsDone": true,   // Vitals are completed
            "sentToDoctor": true, // Mark as sent to doctor
            "sentToDoctorTime": Timestamp(date: Date())
        ]) { error in
            if let error = error {
                print("Error updating appointment: \(error.localizedDescription)")
                completion(false)
            } else {
                print("Successfully sent patient to doctor \(providerName)")
                completion(true)
            }
        }
    }
    
    // New method to update the vitals status
    func updateVitalsStatus(appointmentId: String, completion: @escaping (Bool) -> Void) {
        guard let officeId = selectedOfficeId else {
            print("No office ID selected for updating vitals status")
            completion(false)
            return
        }
        
        print("Updating vitals status for appointment: \(appointmentId)")
        
        let appointmentRef = db.collection("offices")
            .document(officeId)
            .collection("appointments")
            .document(appointmentId)
        
        appointmentRef.updateData([
            "vitalsDone": true,
            "vitalsCompletedTime": Timestamp(date: Date())
        ]) { error in
            if let error = error {
                print("Error updating vitals status: \(error.localizedDescription)")
                completion(false)
            } else {
                print("Successfully updated vitals status to completed")
                completion(true)
            }
        }
    }
    
    // New method to update the seenDoctor status
    func updateSeenDoctorStatus(appointmentId: String, completion: @escaping (Bool) -> Void) {
        guard let officeId = selectedOfficeId else {
            print("No office ID selected for updating seenDoctor status")
            completion(false)
            return
        }
        
        print("Updating seenDoctor status for appointment: \(appointmentId)")
        
        let appointmentRef = db.collection("offices")
            .document(officeId)
            .collection("appointments")
            .document(appointmentId)
        
        appointmentRef.updateData([
            "seenDoctor": true,
            "seenDoctorTime": Timestamp(date: Date())
        ]) { error in
            if let error = error {
                print("Error updating seenDoctor status: \(error.localizedDescription)")
                completion(false)
            } else {
                print("Successfully updated seenDoctor status to completed")
                completion(true)
            }
        }
    }
}

// Updated Provider model
struct Provider: Identifiable {
    let id: String
    let name: String
    let specialty: String
}
