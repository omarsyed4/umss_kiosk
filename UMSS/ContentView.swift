//
//  ContentView.swift
//  UMSS
//
//  Created by Omar Syed on 1/29/25.
//

import SwiftUI
import PDFKit
import PencilKit
import FirebaseFirestore

// Import our modularized files
import Foundation

struct ContentView: View {
    // Navigation and form state
    @State private var currentStep: Int = 0
    @State private var moveDirection: Edge = .trailing
    @State private var isAddressPickerPresented = false
    
    // Your patient form view model and PDF state
    @StateObject private var viewModel = PatientModelViewModel()
    @State private var showPDFPreview = false
    @State private var isGeneratingPDF = false
    @State private var pdfDocument: PDFDocument?
    
    // Office view model
    @StateObject private var officeViewModel = OfficeViewModel()
    
    // Upload service state
    @State private var accessToken: String?
    @State private var uploadStatus: String = ""
    
    // Folder ID for your target folder on Drive
    let folderID = "16b3ZeFMpHft5yN8zGguhABeNjgrTa6Mu"
    
    // Total steps (adjust as needed)
    private var totalSteps: Int { 5 }

    // State for showing reset confirmation
    @State private var showResetConfirmation: Bool = false

    // Add appointment view model
    @StateObject private var appointmentVM = AppointmentViewModel()

    // Add loading state for patient data
    @State private var isLoadingPatientData = false

    // MARK: - Validation Helper Methods
    private func isBasicInfoValid() -> Bool {
        let email = viewModel.patientModel.email.trimmingCharacters(in: .whitespaces)
        let firstName = viewModel.patientModel.firstName.trimmingCharacters(in: .whitespaces)
        let lastName = viewModel.patientModel.lastName.trimmingCharacters(in: .whitespaces)
        let dob = viewModel.patientModel.dob.trimmingCharacters(in: .whitespaces)
        let age = viewModel.patientModel.age.trimmingCharacters(in: .whitespaces)
        let phone = viewModel.patientModel.phone.trimmingCharacters(in: .whitespaces)
        let reasonForVisit = viewModel.patientModel.reasonForVisit.trimmingCharacters(in: .whitespaces)
        
        return !email.isEmpty && 
               !firstName.isEmpty && 
               !lastName.isEmpty && 
               !dob.isEmpty && 
               !age.isEmpty && 
               !phone.isEmpty && 
               !reasonForVisit.isEmpty
    }
    
    private func isDemographicsValid() -> Bool {
        let gender = viewModel.patientModel.selectedGender.trimmingCharacters(in: .whitespaces)
        let race = viewModel.patientModel.selectedRace.trimmingCharacters(in: .whitespaces)
        let maritalStatus = viewModel.patientModel.selectedMaritalStatus.trimmingCharacters(in: .whitespaces)
        let ethnicity = viewModel.patientModel.selectedEthnicity.trimmingCharacters(in: .whitespaces)
        let income = viewModel.patientModel.selectedIncome.trimmingCharacters(in: .whitespaces)
        let address = viewModel.patientModel.address.trimmingCharacters(in: .whitespaces)
        
        return !gender.isEmpty && 
               !race.isEmpty && 
               !maritalStatus.isEmpty && 
               !ethnicity.isEmpty && 
               !income.isEmpty && 
               !address.isEmpty
    }

    // MARK: - Validation for the current step
    private var isCurrentStepValid: Bool {
        switch currentStep {
        case 0:
            return true
        case 1:
            return isBasicInfoValid()
        case 2:
            return isDemographicsValid()
        case 3:
            return viewModel.patientModel.signatureImage != nil
        default:
            return true
        }
    }

    
    var body: some View {
        NavigationView {
            ZStack {
                Color.white.ignoresSafeArea()
                
                // Conditional Content Group:
                Group {
                    if currentStep == 3 {
                        // Step 3 – Signature (now using the component from the Signature folder)
                        SignatureStep(signatureImage: $viewModel.patientModel.signatureImage)
                            .padding(.horizontal, 20)
                    } else {
                        ScrollView {
                            VStack(spacing: 0) {
                                // Step 0 – "Let's Begin"
                                if currentStep == 0 {
                                    HeaderView()
                                    VStack(spacing: 20) {
                                        Text("Let's Begin!")
                                            .font(.largeTitle)
                                            .fontWeight(.bold)
                                            .foregroundColor(UMSSBrand.navy)
                                        
                                        // Appointments section
                                        VStack(spacing: 15) {
                                            if appointmentVM.isLoading {
                                                ProgressView("Checking today's clinic schedule...")
                                                    .padding()
                                            } else if let errorMessage = appointmentVM.errorMessage {
                                                Text("Error: \(errorMessage)")
                                                    .foregroundColor(.red)
                                                    .padding()
                                            } else if !appointmentVM.isClinicDay {
                                                Text("Today is not a scheduled clinic day.")
                                                    .font(.headline)
                                                    .foregroundColor(.secondary)
                                                    .padding()
                                            } else if let office = appointmentVM.todaysOffice {
                                                // Today is a clinic day at this office
                                                VStack(alignment: .leading, spacing: 15) {                                                                                                        
                                                    
                                                    if appointmentVM.appointments.isEmpty {
                                                        Text("No appointments available")
                                                            .foregroundColor(.secondary)
                                                            .padding()
                                                    } else {
                                                        AppointmentListView(
                                                            appointments: appointmentVM.appointments,
                                                            onAppointmentSelected: { appointment in
                                                                handleAppointmentSelection(appointment)
                                                            }
                                                        )
                                                    }
                                                }
                                                .padding()
                                            }
                                            
                                            if isLoadingPatientData {
                                                ProgressView("Loading patient information...")
                                                    .padding()
                                            } else if let office = appointmentVM.todaysOffice {
                                                // Today is a clinic day at this office
                                                VStack(alignment: .leading, spacing: 15) {
                                                    // ...existing code...
                                                }
                                                .padding()
                                            }
                                        }
                                    }
                                }
                                // Step 1 – Basic Info
                                else if currentStep == 1 {
                                    BasicInfoStepView(
                                        email: $viewModel.patientModel.email,
                                        firstName: $viewModel.patientModel.firstName,
                                        lastName: $viewModel.patientModel.lastName,
                                        dob: $viewModel.patientModel.dob,
                                        age: $viewModel.patientModel.age,
                                        phone: $viewModel.patientModel.phone,
                                        reasonForVisit: $viewModel.patientModel.reasonForVisit,
                                        isExistingPatient: $viewModel.patientModel.isExistingPatient,
                                        initialDate: viewModel.patientModel.dateOfBirth
                                    )
                                }
                                // Step 2 – Demographics
                                else if currentStep == 2 {
                                    DemographicsStep(
                                        selectedGender: $viewModel.patientModel.selectedGender,
                                        selectedRace: $viewModel.patientModel.selectedRace,
                                        selectedMaritalStatus: $viewModel.patientModel.selectedMaritalStatus,
                                        selectedEthnicity: $viewModel.patientModel.selectedEthnicity,
                                        selectedIncome: $viewModel.patientModel.selectedIncome,
                                        isMale: $viewModel.patientModel.isMale,
                                        isFemale: $viewModel.patientModel.isFemale,
                                        isWhite: $viewModel.patientModel.isWhite,
                                        isBlack: $viewModel.patientModel.isBlack,
                                        isAsian: $viewModel.patientModel.isAsian,
                                        isAmIndian: $viewModel.patientModel.isAmIndian,
                                        isHispanic: $viewModel.patientModel.isHispanic,
                                        isNonHispanic: $viewModel.patientModel.isNonHispanic,
                                        isSingle: $viewModel.patientModel.isSingle,
                                        isMarried: $viewModel.patientModel.isMarried,
                                        isDivorced: $viewModel.patientModel.isDivorced,
                                        isWidowed: $viewModel.patientModel.isWidowed,
                                        selectedFamilySize: $viewModel.patientModel.selectedFamilySize,
                                        selectedIncomeThreshold: $viewModel.patientModel.selectedIncomeThreshold,
                                        fullAddress: $viewModel.patientModel.rawAddress,
                                        streetAddress: $viewModel.patientModel.address,
                                        city: $viewModel.patientModel.city,
                                        state: $viewModel.patientModel.state,
                                        zip: $viewModel.patientModel.zip,
                                        cityStateZip: $viewModel.patientModel.cityStateZip,
                                        isPickerPresented: $isAddressPickerPresented
                                    )
                                }
                                // Step 4 – Thank You Message
                                else if currentStep == 4 {
                                    VStack(spacing: 30) {
                                        HeaderView()
                                        Text("Thank You!")
                                            .font(.largeTitle)
                                            .fontWeight(.bold)
                                            .foregroundColor(UMSSBrand.navy)
                                        Text("Thanks for filling this out. You may hand this back to a volunteer.")
                                            .font(.headline)
                                            .multilineTextAlignment(.center)
                                            .foregroundColor(.primary)
                                    }
                                    .padding()
                                }
                            }
                            .padding(.horizontal, 20)
                            .transition(
                                .asymmetric(
                                    insertion: .move(edge: moveDirection),
                                    removal: .move(edge: moveDirection == .trailing ? .leading : .trailing)
                                )
                            )
                            .animation(.easeInOut, value: currentStep)
                        }
                    }
                } // End Group
                // Attach sticky navigation buttons using safeAreaInset on the Group
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    if currentStep > 0 { // Only show navigation when not on the start page
                        HStack {
                            if currentStep > 0 {
                                Button(action: {
                                    withAnimation {
                                        moveDirection = .leading
                                        currentStep -= 1
                                    }
                                }) {
                                    Text("Back")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .padding(.vertical, 10)
                                        .padding(.horizontal, 20)
                                        .background(UMSSBrand.navy)
                                        .cornerRadius(8)
                                }
                            }
                            Spacer()
                            if currentStep < totalSteps - 1 {
                                Button(action: {
                                    withAnimation {
                                        moveDirection = .trailing
                                        currentStep += 1
                                    }
                                }) {
                                    Text("Next")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .padding(.vertical, 10)
                                        .padding(.horizontal, 20)
                                        .background(isCurrentStepValid ? UMSSBrand.gold : Color.gray)
                                        .cornerRadius(8)
                                }
                                .disabled(!isCurrentStepValid)
                            } else {
                                Button(action: previewPDFAction) {
                                    if isGeneratingPDF {
                                        ProgressView()
                                    } else {
                                        Text("Preview PDF")
                                            .font(.headline)
                                            .foregroundColor(.white)
                                            .padding(.vertical, 10)
                                            .padding(.horizontal, 20)
                                    }
                                }
                                .background(UMSSBrand.gold)
                                .cornerRadius(8)
                                
                                Text(uploadStatus)
                                    .foregroundColor(.blue)
                                    .padding()
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.white)
                        .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: -2)
                    }
                }
            }
            .navigationBarHidden(true)
            .navigationViewStyle(StackNavigationViewStyle())
            .sheet(isPresented: $showPDFPreview) {
                Group {
                    if let pdfDocument = pdfDocument {
                        PDFPreviewView(pdfDocument: pdfDocument, onUpload: {
                            handleUpload()
                            return .success(())
                        })
                    } else {
                        Text("Error generating PDF.")
                    }
                }
            }
            .sheet(isPresented: $isAddressPickerPresented) {
                GoogleAddressAutocompleteView(
                    rawAddress: $viewModel.patientModel.rawAddress,
                    streetAddress: $viewModel.patientModel.address,
                    city: $viewModel.patientModel.city,
                    state: $viewModel.patientModel.state,
                    zip: $viewModel.patientModel.zip,
                    cityState: $viewModel.patientModel.cityState,
                    cityStateZip: $viewModel.patientModel.cityStateZip,
                    isPresented: $isAddressPickerPresented
                )
            }
            .onAppear {
                // Fetch offices when the view appears
                officeViewModel.fetchOffices()
                
                // Also check for today's clinic
                appointmentVM.checkForTodayClinic()
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }




    
    // MARK: - Navigation Button Subview
    @ViewBuilder
    private func safeAreaInsetView() -> some View {
        HStack {
            if currentStep > 0 {
                Button(action: {
                    withAnimation {
                        moveDirection = .leading
                        currentStep -= 1
                    }
                }) {
                    Text("Back")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 20)
                        .background(UMSSBrand.navy)
                        .cornerRadius(8)
                }
            }
            Spacer()
            if currentStep < totalSteps - 1 {
                Button(action: {
                    withAnimation {
                        moveDirection = .trailing
                        currentStep += 1
                    }
                }) {
                    Text("Next")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 20)
                        .background(isCurrentStepValid ? UMSSBrand.gold : Color.gray)
                        .cornerRadius(8)
                }
                .disabled(!isCurrentStepValid)
            } else {
                Button(action: previewPDFAction) {
                    if isGeneratingPDF {
                        ProgressView()
                    } else {
                        Text("Preview PDF")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.vertical, 10)
                            .padding(.horizontal, 20)
                    }
                }
                .background(UMSSBrand.gold)
                .cornerRadius(8)

                Button(action: {
                    showResetConfirmation = true
                }) {
                    Text("Reset")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 20)
                }
                .background(UMSSBrand.navy)
                .cornerRadius(8)

                
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(Color.white)
        .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: -2)
    }
    
    // MARK: - PDF Preview and Upload Actions
    private func previewPDFAction() {
        isGeneratingPDF = true
        if accessToken == nil {
            getAccessToken { token in
                DispatchQueue.main.async {
                    self.accessToken = token
                    self.generateAndShowPDF()
                }
            }
        } else {
            generateAndShowPDF()
        }
    }
    
    // Generate the PDF and show the preview
    private func generateAndShowPDF() {
        // Generate the PDF using your view model.
        let generatedPDF = viewModel.generateFilledPDF()
        self.pdfDocument = generatedPDF
        isGeneratingPDF = false
        showPDFPreview = true
    }
    
    // Reset the form and state
    private func resetForm() {
        // Reset basic info
        viewModel.patientModel.email = ""
        viewModel.patientModel.firstName = ""
        viewModel.patientModel.lastName = ""
        viewModel.patientModel.dob = ""
        viewModel.patientModel.age = ""
        viewModel.patientModel.phone = ""
        viewModel.patientModel.reasonForVisit = ""
        viewModel.patientModel.isExistingPatient = false
        
        // Reset demographics
        viewModel.patientModel.selectedGender = ""
        viewModel.patientModel.selectedRace = ""
        viewModel.patientModel.selectedMaritalStatus = ""
        viewModel.patientModel.selectedEthnicity = ""
        viewModel.patientModel.selectedIncome = ""
        viewModel.patientModel.address = ""
        
        // Reset signature and address details
        viewModel.patientModel.signatureImage = nil
        viewModel.patientModel.rawAddress = ""
        viewModel.patientModel.city = ""
        viewModel.patientModel.state = ""
        viewModel.patientModel.zip = ""
        viewModel.patientModel.cityStateZip = ""
        
        // Reset additional demographic booleans/values
        viewModel.patientModel.isMale = false
        viewModel.patientModel.isFemale = false
        viewModel.patientModel.isWhite = false
        viewModel.patientModel.isBlack = false
        viewModel.patientModel.isAsian = false
        viewModel.patientModel.isAmIndian = false
        viewModel.patientModel.isHispanic = false
        viewModel.patientModel.isNonHispanic = false
        viewModel.patientModel.isSingle = false
        viewModel.patientModel.isMarried = false
        viewModel.patientModel.isDivorced = false
        viewModel.patientModel.isWidowed = false
        viewModel.patientModel.selectedFamilySize = ""
        viewModel.patientModel.selectedIncomeThreshold = ""
        
        // Reset other state as needed
        currentStep = 0
        uploadStatus = ""
        pdfDocument = nil
    }


    // Called from PDFPreviewView when the user taps Upload.
    private func handleUpload() {
        guard let pdfDocument = pdfDocument,
              let pdfData = pdfDocument.dataRepresentation() else {
            uploadStatus = "Failed to get PDF data."
            return
        }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm"
        let timestamp = dateFormatter.string(from: Date())

        let patientName = "\(viewModel.patientModel.firstName)_\(viewModel.patientModel.lastName)".replacingOccurrences(of: " ", with: "_")

        let fileName = "UMSS_Intake_\(timestamp)_\(patientName).pdf"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        do {
            try pdfData.write(to: tempURL)
        } catch {
            uploadStatus = "Failed to write PDF to temporary file: \(error.localizedDescription)"
            return
        }
        guard let token = accessToken else {
            uploadStatus = "No access token available."
            return
        }
        uploadStatus = "Uploading PDF..."
        uploadFileToDrive(fileURL: tempURL, accessToken: token, folderID: folderID) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let fileID):
                    uploadStatus = "Upload successful. File ID: \(fileID)"
                case .failure(let error):
                    uploadStatus = "Upload error: \(error)"
                }
            }
        }
    }

    // Add this function in the ContentView struct
    private func handleAppointmentSelection(_ appointment: Appointment) {
        // If the appointment is booked, try to load patient data
        if appointment.booked == true && !appointment.patientId.isEmpty {
            isLoadingPatientData = true
            
            // Set the appointment ID in the view model
            viewModel.patientModel.appointmentId = appointment.id
            
            // Fetch patient data from Firestore
            viewModel.fetchPatientData(patientId: appointment.patientId) { success in
                DispatchQueue.main.async {
                    self.isLoadingPatientData = false
                    
                    if success {
                        print("Successfully loaded patient data, navigating to basic info step")
                        
                        // Navigate to the basic info step
                        withAnimation {
                            moveDirection = .trailing
                            currentStep = 1
                        }
                    } else {
                        print("Failed to load patient data")
                        // Handle error - maybe show an alert
                    }
                }
            }
        } else {
            // For walk-ins, start a new patient form and assign this appointment
            viewModel.patientModel.appointmentId = appointment.id
            
            // Reset any existing patient data
            viewModel.resetPatientData()
        }
    }
}
