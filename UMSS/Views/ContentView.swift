//
//  ContentView.swift
//  UMSS
//
//  Created by Omar Syed on 1/29/25.
//

import SwiftUI
import PDFKit
import PencilKit

struct ContentView: View {
    // Navigation and form state
    @State private var currentStep: Int = 0
    @State private var moveDirection: Edge = .trailing
    @State private var isAddressPickerPresented = false
    
    // Your patient form view model and PDF state
    @StateObject private var viewModel = PatientFormViewModel()
    @State private var showPDFPreview = false
    @State private var isGeneratingPDF = false
    @State private var pdfDocument: PDFDocument?
    
    // Upload service state
    @State private var accessToken: String?
    @State private var uploadStatus: String = ""
    
    // Folder ID for your target folder on Drive
    let folderID = "16b3ZeFMpHft5yN8zGguhABeNjgrTa6Mu"
    
    // Total steps (adjust as needed)
    private var totalSteps: Int { 5 }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.white.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    if currentStep == 0 {
                        HeaderView()
                    }
                    
                    ScrollView {
                        VStack(spacing: 0) {
                            // Step 0 – “Let’s Begin”
                            if currentStep == 0 {
                                VStack(spacing: 20) {
                                    Text("Let's Begin!")
                                        .font(.largeTitle)
                                        .fontWeight(.bold)
                                        .foregroundColor(UMSSBrand.navy)
                                    Text("Welcome to the intake process.\nTap Next to get started.")
                                        .multilineTextAlignment(.center)
                                        .foregroundColor(.primary)
                                }
                            }
                            // Step 1 – Basic Info
                            else if currentStep == 1 {
                                BasicInfoStepView(
                                    email: $viewModel.patientForm.email,
                                    firstName: $viewModel.patientForm.firstName,
                                    lastName: $viewModel.patientForm.lastName,
                                    dob: $viewModel.patientForm.dob,
                                    age: $viewModel.patientForm.age,
                                    phone: $viewModel.patientForm.phone,
                                    reasonForVisit: $viewModel.patientForm.reasonForVisit,
                                    isExistingPatient: $viewModel.patientForm.isExistingPatient
                                )
                            }
                            // Step 2 – Demographics
                            else if currentStep == 2 {
                                DemographicsStep(
                                    selectedGender: $viewModel.patientForm.selectedGender,
                                    selectedRace: $viewModel.patientForm.selectedRace,
                                    selectedMaritalStatus: $viewModel.patientForm.selectedMaritalStatus,
                                    selectedEthnicity: $viewModel.patientForm.selectedEthnicity,
                                    selectedIncome: $viewModel.patientForm.selectedIncome,
                                    isMale: $viewModel.patientForm.isMale,
                                    isFemale: $viewModel.patientForm.isFemale,
                                    isWhite: $viewModel.patientForm.isWhite,
                                    isBlack: $viewModel.patientForm.isBlack,
                                    isAsian: $viewModel.patientForm.isAsian,
                                    isAmIndian: $viewModel.patientForm.isAmIndian,
                                    isHispanic: $viewModel.patientForm.isHispanic,
                                    isNonHispanic: $viewModel.patientForm.isNonHispanic,
                                    isSingle: $viewModel.patientForm.isSingle,
                                    isMarried: $viewModel.patientForm.isMarried,
                                    isDivorced: $viewModel.patientForm.isDivorced,
                                    isWidowed: $viewModel.patientForm.isWidowed,
                                    selectedFamilySize: $viewModel.patientForm.selectedFamilySize,
                                    selectedIncomeThreshold: $viewModel.patientForm.selectedIncomeThreshold,
                                    fullAddress: $viewModel.patientForm.rawAddress,
                                    streetAddress: $viewModel.patientForm.address,
                                    city: $viewModel.patientForm.city,
                                    state: $viewModel.patientForm.state,
                                    zip: $viewModel.patientForm.zip,
                                    cityStateZip: $viewModel.patientForm.cityStateZip,
                                    isPickerPresented: $isAddressPickerPresented
                                )
                            }
                            // Step 3 – Signature
                            else if currentStep == 3 {
                                SignatureStep(
                                    signatureImage: $viewModel.patientForm.signatureImage
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
                    
                    // Sticky Navigation Buttons
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
                                        .background(UMSSBrand.gold)
                                        .cornerRadius(8)
                                }
                            } else {
                                Button(action: {
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
                                }) {
                                    if isGeneratingPDF {
                                        ProgressView()
                                    } else {
                                        Text("Preview PDF")
                                            .font(.headline)
                                            .foregroundColor(.white)
                                            .padding(.vertical, 10)
                                            .padding(.horizontal, 20)
                                            .background(UMSSBrand.gold)
                                            .cornerRadius(8)
                                    }
                                }
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
            .sheet(isPresented: $showPDFPreview) {
                Group {
                    if let pdfDocument = pdfDocument {
                        PDFPreviewView(pdfDocument: pdfDocument, onUpload: {
                            // Write the PDF to a temporary URL and upload it.
                            guard let pdfData = pdfDocument.dataRepresentation() else {
                                uploadStatus = "Failed to get PDF data."
                                return .failure(DriveUploaderError.fileDataUnavailable)
                            }
                            let dateFormatter = DateFormatter()
                            dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm"
                            let timestamp = dateFormatter.string(from: Date())

                            let patientName = "\(viewModel.patientForm.firstName)_\(viewModel.patientForm.lastName)".replacingOccurrences(of: " ", with: "_")

                            let fileName = "UMSS_Intake_\(timestamp)_\(patientName).pdf"
                            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
                            do {
                                try pdfData.write(to: tempURL)
                            } catch {
                                uploadStatus = "Failed to write PDF to temporary file: \(error.localizedDescription)"
                                return .failure(error)
                            }
                            guard let token = accessToken else {
                                uploadStatus = "No access token available."
                                return .failure(DriveUploaderError.invalidResponse)
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
                            // Return success immediately since the asynchronous operation will complete later.
                            return .success(())
                        })
                    } else {
                        Text("Error generating PDF.")
                    }
                }
            }
            .sheet(isPresented: $isAddressPickerPresented) {
                GoogleAddressAutocompleteView(
                    rawAddress: $viewModel.patientForm.rawAddress,
                    streetAddress: $viewModel.patientForm.address,
                    city: $viewModel.patientForm.city,
                    state: $viewModel.patientForm.state,
                    zip: $viewModel.patientForm.zip,
                    cityState: $viewModel.patientForm.cityState,
                    cityStateZip: $viewModel.patientForm.cityStateZip,
                    isPresented: $isAddressPickerPresented
                )
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
                        .background(UMSSBrand.gold)
                        .cornerRadius(8)
                }
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
    
    private func generateAndShowPDF() {
        // Generate the PDF using your view model.
        let generatedPDF = viewModel.generateFilledPDF()
        self.pdfDocument = generatedPDF
        isGeneratingPDF = false
        showPDFPreview = true
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

        let patientName = "\(viewModel.patientForm.firstName)_\(viewModel.patientForm.lastName)".replacingOccurrences(of: " ", with: "_")

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
    @Binding var reasonForVisit: String  // NEW binding for reason for visit
    @Binding var isExistingPatient: Bool
    
    
    @State private var selectedDate: Date = Date()
    
    // Custom Number Pad Layout for Phone Entry
    private let numberPadButtons: [[String]] = [
        ["1", "2", "3"],
        ["4", "5", "6"],
        ["7", "8", "9"],
        ["Clear", "0", "Delete"]
    ]
    
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
                
                // MARK: - Basic Information Section
                SectionCard(title: "Basic Information") {
                    VStack(spacing: 20) {
                        HStack(spacing: 10) {
                            TextField("First Name", text: $firstName)
                                .keyboardType(.emailAddress)
                                .padding(12)
                                .background(Color.white)
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                                )
                            
                            TextField("Last Name", text: $lastName)
                                .keyboardType(.emailAddress)
                                .padding(12)
                                .background(Color.white)
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                                )
                        }

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
                        // New: Row with Date of Birth and Age fields
                        HStack(spacing: 10) {
                            // Date of Birth Field
                            HStack(spacing: 10) {
                                Text("Date of Birth")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                DatePicker("", selection: $selectedDate, displayedComponents: .date)
                                    .datePickerStyle(CompactDatePickerStyle())
                                    .labelsHidden()
                                    .onChange(of: selectedDate) { newValue in
                                        let formatter = DateFormatter()
                                        formatter.dateFormat = "MM/dd/yyyy"
                                        dob = formatter.string(from: newValue)
                                    }
                            }
                            .frame(maxWidth: .infinity) // Ensures equal width
                            .padding(12)
                            .background(Color.white)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                            )
                            
                            // Age Field
                            VStack(alignment: .leading, spacing: 5) {
                                TextField("Age", text: $age)
                                    .keyboardType(.numberPad)
                            }
                            .frame(maxWidth: .infinity) // Ensures equal width
                            .padding(12)
                            .background(Color.white)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                            )
                        }
                    }
                }
                
                // NEW: Reason for Visit Section
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
                
                // MARK: - New Or Existing Patient Section
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
                
                // MARK: - Phone Number Section
                SectionCard(title: "Phone Number") {
                    VStack(spacing: 20) {
                        // Display the Entered Phone Number
                        Text(phone)
                            .font(.title)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.white)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                            )
                        
                        // Custom Number Pad Grid
                        VStack(spacing: 15) {
                            ForEach(numberPadButtons, id: \.self) { row in
                                HStack(spacing: 15) {
                                    ForEach(row, id: \.self) { button in
                                        Button(action: {
                                            handleButtonPress(button)
                                        }) {
                                            Text(button)
                                                .font(.title2)
                                                .frame(width: 80, height: 80)
                                                .background(Color(.systemGray5))
                                                .cornerRadius(12)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .padding(.vertical, 30)
            .padding(.horizontal)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }
    
    // MARK: - Custom Number Pad Handler
    private func handleButtonPress(_ input: String) {
        switch input {
        case "Clear":
            phone = ""
        case "Delete":
            if !phone.isEmpty { phone.removeLast() }
        default:
            phone.append(input)
        }
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


// MARK: - SignatureCanvasView
/// A SwiftUI wrapper around PencilKit's PKCanvasView.
struct SignatureCanvasView: UIViewRepresentable {
    @Binding var canvasView: PKCanvasView
    
    func makeUIView(context: Context) -> UIView {
        // Create a container view for the canvas + guidelines
        let containerView = UIView()
        containerView.backgroundColor = .white
        containerView.layer.borderColor = UIColor.lightGray.cgColor
        containerView.layer.borderWidth = 1.0
        containerView.layer.cornerRadius = 8.0
        
        // Add the PKCanvasView as a subview
        canvasView.backgroundColor = .clear
        canvasView.drawingPolicy = .anyInput
        canvasView.tool = PKInkingTool(.pen, color: .black, width: 5)
        canvasView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(canvasView)
        
        // Add constraints to fill the container
        NSLayoutConstraint.activate([
            canvasView.topAnchor.constraint(equalTo: containerView.topAnchor),
            canvasView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            canvasView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            canvasView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor)
        ])
        
        // Add dashed line (repositioned in updateUIView)
        let dashedLineLayer = CAShapeLayer()
        dashedLineLayer.strokeColor = UIColor.gray.cgColor
        dashedLineLayer.lineWidth = 1.0
        dashedLineLayer.lineDashPattern = [4, 4]
        containerView.layer.addSublayer(dashedLineLayer)
        context.coordinator.dashedLineLayer = dashedLineLayer
        
        return containerView
    }
    
    func updateUIView(_ containerView: UIView, context: Context) {
        // Update dashed line position whenever the container's bounds change
        guard let dashedLine = context.coordinator.dashedLineLayer else { return }
        let yPosition = containerView.bounds.height - 40 // Place near bottom
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 20, y: yPosition))
        path.addLine(to: CGPoint(x: containerView.bounds.width - 20, y: yPosition))
        dashedLine.path = path.cgPath
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator {
        var dashedLineLayer: CAShapeLayer?
    }
}

// MARK: - SignatureStep
struct SignatureStep: View {
    /// Holds the user's signature image.
    @Binding var signatureImage: UIImage?
    
    // We are removing the date text field per your request, so no `date` binding is needed.
    
    /// The PencilKit canvas
    @State private var canvasView = PKCanvasView()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("DISCLAIMER OF MEDICAL INFORMATION AUTHORIZATION")
                    .font(.headline)
                // Disclaimers / Authorization Text
                Text("I have read and understand the Alert for Electronic Communications and agree that e-mail messages may include protected health information about me / the patient whenever necessary.\n\nMy signature on this Authorization indicates that I am giving permission for the uses and disclosures of the protected health information described above. The facility, its employees, officers, and physicians are hereby released from any legal responsibility or liability for disclosures of the above information to the extent indicated and authorized herein.\n\nI understand this authorization may be revoked in writing at any time, except to the extent that action has been taken in reliance on this authorization. Unless otherwise revoked in writing, this authorization will expire 1 year from the date of execution. A photocopy or FAX of this document is valid as the original.\n\nLIABILITY WAIVER: This liability waiver is a LEGAL DOCUMENT. This liability waiver is a “catch all”. By signing this waiver, you or your representative acknowledge that you or your representative WILL NOT seek civil or federal penalties or compensation in any court in the event of injury or death incurred while in the facility/facility premises against the aforementioned owner / tenant of the facility.\n\nTo the best of my knowledge the above information is complete and accurate.")
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .padding(.horizontal)
                
                // Acknowledgement Section
                VStack(alignment: .leading, spacing: 10) {
                    Text("ACKNOWLEDGEMENT AND AUTHORIZATION:")
                        .font(.headline)
                    Text(" - I have read and understand the HIPAA/Privacy Policy for United Medical and Social Services Clinic")
                    Text(" - I authorize United Medical and Social Services Clinic to obtain/have access to my medication history")
                    Text(" - I authorize my provider’s office to contact me by my mobile phone")
                }
                .font(.subheadline)
                .foregroundColor(.primary)
                .padding(.horizontal)
                
                Divider().padding(.vertical, 10)
                
                Text("Signature")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                // The PencilKit wrapper
                SignatureCanvasView(canvasView: $canvasView)
                    .frame(height: 300)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                    .padding(.horizontal)
                
                // Buttons to handle the drawing
                HStack(spacing: 40) {
                    Button("Clear") {
                        // Clears the canvas
                        canvasView.drawing = PKDrawing()
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    .background(Color.red.opacity(0.1))
                    .foregroundColor(.red)
                    .cornerRadius(8)
                    
                    Button("Save Signature") {
                        // Extract an image from the drawing
                        let image = canvasView.drawing
                            .image(from: canvasView.bounds, scale: 1.0)
                        
                        // Store the image in your binding
                        signatureImage = image
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(8)
                }
                .padding(.bottom, 30)
            }
            .padding(.top, 20)
        }
        .frame(maxWidth: .infinity)
        .background(Color.white.ignoresSafeArea())
    }
}
