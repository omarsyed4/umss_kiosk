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
                                                    Text("Today's Clinic")
                                                        .font(.title2)
                                                        .fontWeight(.semibold)
                                                                                                        
                                                    
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
                                                .background(
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .fill(Color(.systemGray6))
                                                )
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
                                        isExistingPatient: $viewModel.patientModel.isExistingPatient
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
            // TODO: Load existing patient data
            print("Loading patient with ID: \(appointment.patientId)")
            
            // For now, just set the appointment ID in the view model
            viewModel.patientModel.appointmentId = appointment.id
            
        } else {
            // For walk-ins, start a new patient form and assign this appointment
            viewModel.patientModel.appointmentId = appointment.id
            
            // Reset any existing patient data
            viewModel.resetPatientData()
            
        }
    }
}





/// Formats a string of digits into (XXX) XXX-XXXX format.
func formatPhoneNumber(_ number: String) -> String {
    // Limit to maximum 10 digits
    let maxDigits = String(number.prefix(10))
    let count = maxDigits.count
    
    switch count {
    case 0...3:
        return maxDigits
    case 4...6:
        let area = maxDigits.prefix(3)
        let prefix = maxDigits.suffix(count - 3)
        return "(\(area)) \(prefix)"
    default:
        let area = maxDigits.prefix(3)
        let prefix = maxDigits.dropFirst(3).prefix(3)
        let lineNumber = maxDigits.dropFirst(6)
        return "(\(area)) \(prefix)-\(lineNumber)"
    }
}



// MARK: - HeaderView
struct HeaderView: View {
    var body: some View {
        VStack(spacing: 0) {
            Image("UMSS Logo")
                .resizable()
                .scaledToFit()
                .frame(width: 400, height: 400) // Adjust as needed
        }
        .padding(.top, 0)
    }
}



// MARK: - BasicInfoStepView
struct BasicInfoStepView: View {
    // Basic Information Bindings
    @Binding var email: String
    @Binding var firstName: String
    @Binding var lastName: String
    @Binding var dob: String
    @Binding var age: String
    @Binding var phone: String
    @Binding var reasonForVisit: String
    @Binding var isExistingPatient: Bool
    
    @State private var selectedDate: Date = Date()
    
        
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 8) {
                    Text("Basic Information")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text("Please provide your basic details")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 20)
                
                // MARK: - Basic Information Section (Names, DOB, Age)
                SectionCard(title: "Basic Information") {
                    // A single HStack containing First/Last Name and DOB side by side
                    HStack(spacing: 20) {

                            TextField("First Name", text: $firstName)
                                .padding(12)
                                .background(Color.white)
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                                )

                            TextField("Last Name", text: $lastName)
                                .padding(12)
                                .background(Color.white)
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                                )
                        

                        // DOB Field
                        VStack(spacing: 10) {
                            HStack(spacing: 10) {
                                Text("DOB")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                DatePicker("", selection: $selectedDate, displayedComponents: .date)
                                    .datePickerStyle(CompactDatePickerStyle())
                                    .labelsHidden()
                                    .onChange(of: selectedDate) { newValue in
                                        // Update dob as formatted string
                                        let formatter = DateFormatter()
                                        formatter.dateFormat = "MM/dd/yyyy"
                                        dob = formatter.string(from: newValue)
                                        
                                        // Calculate age from the selected date
                                        let now = Date()
                                        let ageComponents = Calendar.current.dateComponents([.year], from: newValue, to: now)
                                        age = "\(ageComponents.year ?? 0)"
                                    }
                            }
                            .padding(12)
                            .background(Color.white)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                            )

                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                
                
                
                
                
                // MARK: - New Contact Info Section (Email and Phone in One Row)
                SectionCard(title: "Contact Info") {
                    VStack(spacing: 20) {
                        // Email Field
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Email")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            // Email Field with Domain Buttons
                            HStack(spacing: 10) {
                                
                                VStack(alignment: .leading, spacing: 10) {
                                    TextField("Email", text: $email)
                                        .keyboardType(.emailAddress)
                                        .padding(12)
                                        .background(Color.white)
                                        .cornerRadius(8)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                                        )
                                    
                                    // Horizontal list of domain buttons
                                    HStack(spacing: 10) {
                                        Button(
                                            action: {
                                            if !email.contains("@") {
                                                email += "@gmail.com"
                                            }
                                        }) {
                                            Text("@gmail.com")
                                                .padding(10)
                                                .background(UMSSBrand.navy)
                                                .foregroundColor(.white)
                                                .cornerRadius(8)
                                        }
                                        
                                        Button(action: {
                                            if !email.contains("@") {
                                                email += "@hotmail.com"
                                            }
                                        }) {
                                            Text("@hotmail.com")
                                                .padding(10)
                                                .background(UMSSBrand.navy)
                                                .foregroundColor(.white)
                                                .cornerRadius(8)
                                        }
                                        
                                        Button(action: {
                                            if !email.contains("@") {
                                                email += "@yahoo.com"
                                            }
                                        }) {
                                            Text("@yahoo.com")
                                                .padding(10)
                                                .background(UMSSBrand.navy)
                                                .foregroundColor(.white)
                                                .cornerRadius(8)
                                        }
                                        
                                        Button(action: {
                                            if !email.contains("@") {
                                                email += "@outlook.com"
                                            }
                                        }) {
                                            Text("@outlook.com")
                                                .padding(10)
                                                .background(UMSSBrand.navy)
                                                .foregroundColor(.white)
                                                .cornerRadius(8)
                                        }
                                        
                                        Button(action: {
                                            if !email.contains("@") {
                                                email += "@icloud.com"
                                            }
                                        }) {
                                            Text("@icloud.com")
                                                .padding(10)
                                                .background(UMSSBrand.navy)
                                                .foregroundColor(.white)
                                                .cornerRadius(8)
                                        }
                                    }
                                }
                            }

                        }
                        VStack {
                            // Phone Field
                            VStack(alignment: .leading, spacing: 5) {
                                Text("Phone")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                TextField("Phone", text: $phone)
                                    .keyboardType(.numberPad)
                                    .padding(12)
                                    .background(Color.white)
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                                    )
                                    .onChange(of: phone) { newValue in
                                        // Filter out non-digit characters
                                        let digits = newValue.filter { $0.isNumber }
                                        // Format the number
                                        phone = formatPhoneNumber(digits)
                                    }
                            }
                        }
                        

                    }
                }
                
                // MARK: - Reason for Visit Section
                SectionCard(title: "Reason for Visit") {
                    VStack(spacing: 12) {
                        TextEditor(text: $reasonForVisit)
                            .frame(height: 100)
                            .padding(12)
                            .background(Color.white)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                            )
                    }
                }
                
                // MARK: - New or Existing Patient Section
                SectionCard(title: "New Or Existing Patient") {
                    VStack(spacing: 12) {
                        ForEach(["New Patient", "Existing Patient"], id: \.self) { option in
                            ChoiceRow(
                                title: option,
                                isSelected: (option == "Existing Patient" && isExistingPatient) ||
                                            (option == "New Patient" && !isExistingPatient)
                            ) {
                                isExistingPatient = (option == "Existing Patient")
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .padding(.vertical, 30)
            .padding(.horizontal)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }
    
}




// MARK: - DemographicsStep
struct DemographicsStep: View {
    // Existing demographic bindings
    @Binding var selectedGender: String
    @Binding var selectedRace: String
    @Binding var selectedMaritalStatus: String
    @Binding var selectedEthnicity: String
    @Binding var selectedIncome: String  // NEW: Binding for income
    
    // Gender-related bindings
    @Binding var isMale: Bool
    @Binding var isFemale: Bool
    
    // Race-related bindings
    @Binding var isWhite: Bool
    @Binding var isBlack: Bool
    @Binding var isAsian: Bool
    @Binding var isAmIndian: Bool
    
    // Ethnicity-related bindings
    @Binding var isHispanic: Bool
    @Binding var isNonHispanic: Bool
    
    // Marital status-related bindings
    @Binding var isSingle: Bool
    @Binding var isMarried: Bool
    @Binding var isDivorced: Bool
    @Binding var isWidowed: Bool

    @Binding var selectedFamilySize: String
    @Binding var selectedIncomeThreshold: String

    // Address-related bindings
    @Binding var fullAddress: String
    @Binding var streetAddress: String
    @Binding var city: String
    @Binding var state: String
    @Binding var zip: String
    @Binding var cityStateZip: String
    @Binding var isPickerPresented: Bool

    private let genderOptions = ["Male", "Female"]
    private let raceOptions = ["White", "Black / African American", "Asian", "American Indian"]
    private let maritalStatusOptions = ["Single", "Married", "Divorced", "Widowed"]
    private let ethnicityOptions = ["Hispanic/Latino", "Not Hispanic/Latino"]
    private let incomeOptions = [
        "1 Person - $2430 or Less",
        "2 Persons - $3287 or Less",
        "3 Persons - $4143 or Less",
        "4 Persons - $5000 or Less",
        "Zero - No Income"
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 8) {
                    Text("Demographic Information")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Please provide your demographic details")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 20)
                
                // Gender Section
                SectionCard(title: "Gender") {
                    HStack(spacing: 12) {
                        ForEach(genderOptions, id: \.self) { option in
                            ChoicePill(
                                title: option,
                                isSelected: selectedGender == option
                            ) {
                                selectedGender = option
                                if selectedGender == "Male" {
                                    isMale = true
                                    isFemale = false
                                } else {
                                    isMale = false
                                    isFemale = true
                                }
                            }
                        }
                    }
                    .padding(.top, 8)
                }
                
                // Race Section
                SectionCard(title: "Race") {
                    VStack(spacing: 12) {
                        ForEach(raceOptions, id: \.self) { option in
                            ChoiceRow(
                                title: option,
                                isSelected: selectedRace == option
                            ) {
                                selectedRace = option
                                if option == "White" {
                                    isWhite = true
                                    isBlack = false
                                    isAsian = false
                                    isAmIndian = false
                                } else if option == "Black / African American" {
                                    isWhite = false
                                    isBlack = true
                                    isAsian = false
                                    isAmIndian = false
                                } else if option == "Asian" {
                                    isWhite = false
                                    isBlack = false
                                    isAsian = true
                                    isAmIndian = false
                                } else if option == "American Indian" {
                                    isWhite = false
                                    isBlack = false
                                    isAsian = false
                                    isAmIndian = true
                                }
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                // Marital Status Section
                SectionCard(title: "Marital Status") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(maritalStatusOptions, id: \.self) { option in
                                ChoicePill(
                                    title: option,
                                    isSelected: selectedMaritalStatus == option
                                ) {
                                    selectedMaritalStatus = option
                                    if option == "Single" {
                                        isSingle = true
                                        isMarried = false
                                        isDivorced = false
                                        isWidowed = false
                                    } else if option == "Married" {
                                        isSingle = false
                                        isMarried = true
                                        isDivorced = false
                                        isWidowed = false
                                    } else if option == "Divorced" {
                                        isSingle = false
                                        isMarried = false
                                        isDivorced = true
                                        isWidowed = false
                                    } else if option == "Widowed" {
                                        isSingle = false
                                        isMarried = false
                                        isDivorced = false
                                        isWidowed = true
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
                
                // Ethnicity Section
                SectionCard(title: "Ethnicity") {
                    VStack(spacing: 12) {
                        ForEach(ethnicityOptions, id: \.self) { option in
                            ChoiceRow(
                                title: option,
                                isSelected: selectedEthnicity == option
                            ) {
                                selectedEthnicity = option
                                if option == "Hispanic/Latino" {
                                    isHispanic = true
                                    isNonHispanic = false
                                } else {
                                    isHispanic = false
                                    isNonHispanic = true
                                }
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                // Income Section
                SectionCard(title: "Income") {
                    VStack(spacing: 12) {
                        ForEach(incomeOptions, id: \.self) { option in
                            ChoiceRow(
                                title: option,
                                isSelected: selectedIncome == option
                            ) {
                                selectedIncome = option
                                // Split the option String into two parts separated by " - "
                                let parts = option.components(separatedBy: " - ")
                                if parts.count == 2 {
                                    selectedFamilySize = parts[0].trimmingCharacters(in: .whitespaces)
                                    selectedIncomeThreshold = parts[1].trimmingCharacters(in: .whitespaces)
                                }
                            }

                        }
                    }
                    .padding(.vertical, 8)
                }
                
                // Address Section (integrated widget)
                SectionCard(title: "Address") {
                    Button(action: {
                        isPickerPresented = true
                    }) {
                        HStack(spacing: 15) {
                            Image(systemName: "mappin.and.ellipse")
                                .foregroundColor(.blue)
                                .font(.title2)
                            
                            VStack(alignment: .leading, spacing: 5) {
                                if fullAddress.isEmpty {
                                    Text("Tap to select your address")
                                        .font(.body)
                                        .foregroundColor(.blue)
                                        .underline()
                                } else {
                                    Text("Selected Address:")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    Text(fullAddress)
                                        .font(.body)
                                        .foregroundColor(.primary)
                                        .multilineTextAlignment(.leading)
                                }
                            }
                            
                            Spacer()
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemGray6))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.blue.opacity(0.7), lineWidth: 1)
                        )
                        .animation(.easeInOut, value: fullAddress)
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }
}




// Reusable Section Card
struct SectionCard<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
                .padding(.horizontal, 16)
            
            VStack {
                content
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(.systemGray4), lineWidth: 1)
            )
        }
    }
}

// Reusable Choice Components
struct ChoicePill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .padding(.vertical, 10)
                .padding(.horizontal, 16)
                .foregroundColor(isSelected ? .white : .primary)
                .background(isSelected ? Color.blue : Color(.systemGray5))
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(isSelected ? Color.blue : Color(.systemGray3), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

struct ChoiceRow: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(Color(.tertiarySystemGroupedBackground))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.blue : Color(.systemGray4), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

