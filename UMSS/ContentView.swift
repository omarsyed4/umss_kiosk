//
//  ContentView.swift
//  UMSS
//
//  Created by Omar Syed on 1/29/25.
//  Revised by [Your Name] on [Today’s Date]
//

import SwiftUI
import PDFKit
import PencilKit
import FirebaseFirestore
import Foundation

struct ContentView: View {
    // MARK: - Patient Flow Steps (dashboard is separate)
    enum PatientFlowStep: String, CaseIterable, Identifiable {
        case basicInfo = "Basic Info"
        case demographics = "Demographics"
        case signature = "Signature"
        case uploadDoc = "Check-In Doc Upload"
        case vitals = "Vitals"
        
        var id: Self { self }
    }
    
    // MARK: - State Variables
    // Flag for showing patient flow vs. dashboard.
    @State private var inPatientFlow: Bool = false
    // The currently selected step in the patient flow.
    @State private var selectedFlowStep: PatientFlowStep = .basicInfo
    
    @StateObject private var viewModel = PatientModelViewModel()
    @StateObject private var appointmentVM = AppointmentViewModel()
    @StateObject private var officeViewModel = OfficeViewModel()
    
    // PDF and upload states.
    @State private var showPDFPreview = false
    @State private var isGeneratingPDF = false
    @State private var pdfDocument: PDFDocument?
    @State private var accessToken: String?
    @State private var uploadStatus: String = ""
    
    // Additional states.
    @State private var isAddressPickerPresented = false
    @State private var isLoadingPatientData = false
    @State private var isWalkIn: Bool = true

    // Folder ID for Drive uploads.
    let folderID = "16b3ZeFMpHft5yN8zGguhABeNjgrTa6Mu"
    
    // NEW vitals completion state
    @State private var isVitalsComplete: Bool = false
    @State private var isUploadDocComplete: Bool = false  // NEW uploadDoc completion state
    
    // MARK: - Computed Validation Properties
    private var isBasicInfoComplete: Bool {
        let model = viewModel.patientModel
        let emailValid     = !model.email.trimmingCharacters(in: .whitespaces).isEmpty
        let firstNameValid = !model.firstName.trimmingCharacters(in: .whitespaces).isEmpty
        let lastNameValid  = !model.lastName.trimmingCharacters(in: .whitespaces).isEmpty
        let phoneValid     = !model.phone.trimmingCharacters(in: .whitespaces).isEmpty
        let reasonValid    = !model.reasonForVisit.trimmingCharacters(in: .whitespaces).isEmpty
        let dobValid       = !model.dob.trimmingCharacters(in: .whitespaces).isEmpty
        // For appointments (isWalkIn == false), age check is skipped
        let ageValid       = isWalkIn ? !model.age.trimmingCharacters(in: .whitespaces).isEmpty : true

        let complete = (emailValid && firstNameValid && lastNameValid && phoneValid && reasonValid && dobValid && ageValid)
        if !complete {
            var missingFields = [String]()
            if !emailValid { missingFields.append("email") }
            if !firstNameValid { missingFields.append("firstName") }
            if !lastNameValid { missingFields.append("lastName") }
            if !dobValid { missingFields.append("dob") }
            if isWalkIn && !ageValid { missingFields.append("age") }
            if !phoneValid { missingFields.append("phone") }
            if !reasonValid { missingFields.append("reasonForVisit") }
            print("BasicInfo incomplete – missing: \(missingFields)")
        }
        return complete
    }

    
    
    private var isDemographicsComplete: Bool {
        let model = viewModel.patientModel
        return !model.selectedGender.trimmingCharacters(in: .whitespaces).isEmpty &&
               !model.selectedRace.trimmingCharacters(in: .whitespaces).isEmpty &&
               !model.selectedMaritalStatus.trimmingCharacters(in: .whitespaces).isEmpty &&
               !model.selectedEthnicity.trimmingCharacters(in: .whitespaces).isEmpty &&
               !model.selectedIncome.trimmingCharacters(in: .whitespaces).isEmpty &&
               !model.address.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    private var isSignatureComplete: Bool {
        return viewModel.patientModel.signatureImage != nil
    }
    
    // The steps that the user is allowed to navigate to.
    private var allowedSteps: [PatientFlowStep] {
        var steps: [PatientFlowStep] = [.basicInfo]
        if isBasicInfoComplete {
            steps.append(.demographics)
            if isDemographicsComplete {
                steps.append(.signature)
                if isSignatureComplete {
                    steps.append(.uploadDoc)
                    if isUploadDocComplete {
                        steps.append(.vitals)
                    }
                }
            }
        }
        return steps
    }
    
    var body: some View {
        ZStack {
            if !inPatientFlow {
                // Dashboard is the entry point – no sidebar.
                DashboardView(
                    appointmentVM: appointmentVM,
                    handleWalkIn: {
                        viewModel.resetPatientData()
                        inPatientFlow = true
                        selectedFlowStep = .basicInfo
                    },
                    handleAppointment: { appointment in
                        handleAppointmentSelection(appointment)
                    }
                )
            } else {
                // Patient Flow: NavigationView with a sidebar.
                NavigationView {
                    // Sidebar with icons, step checks, and a Cancel button.
                    VStack(alignment: .leading) {
                        List(PatientFlowStep.allCases, id: \.self) { step in
                            let isEnabled = (allowedSteps.contains(step) || step == .basicInfo)
                            HStack {
                                // Icon for each step.
                                Group {
                                    switch step {
                                    case .basicInfo:
                                        Image(systemName: "person.fill")
                                    case .demographics:
                                        Image(systemName: "info.bubble")
                                    case .signature:
                                        Image(systemName: "signature")
                                    case .uploadDoc:
                                        Image(systemName: "ecg.text.page")
                                    case .vitals:
                                        Image(systemName: "heart.text.clipboard")
                                    }
                                }
                                .frame(width: 24)
                                
                                Text(step.rawValue)
                                
                                Spacer()
                                // Show a checkmark if the step is complete.
                                if (step == .basicInfo && isBasicInfoComplete) ||
                                   (step == .demographics && isDemographicsComplete) ||
                                   (step == .vitals && isVitalsComplete) ||
                                   (step == .signature && isSignatureComplete) {
                                    Image(systemName: "checkmark.rectangle.fill")
                                        .foregroundColor(.green)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                // Only allow navigating to a step if it is allowed (or if it’s a previous step).
                                let allSteps = PatientFlowStep.allCases
                                if let tappedIndex = allSteps.firstIndex(of: step),
                                   let currentIndex = allSteps.firstIndex(of: selectedFlowStep),
                                   tappedIndex <= currentIndex || isEnabled {
                                    selectedFlowStep = step
                                }
                            }
                            .disabled(!isEnabled)
                            .foregroundColor(isEnabled ? .primary : .gray)
                        }


                        Spacer()
                        // Cancel button to reset patient data and return to dashboard.
                        Button(action: {
                            viewModel.resetPatientData()
                            inPatientFlow = false
                        }) {
                            HStack {
                                Image(systemName: "xmark.bin")
                                Text("Cancel")
                            }
                            .foregroundColor(.red)
                            .padding()
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .frame(minWidth: 250)
                    .listStyle(SidebarListStyle())
                    .navigationTitle("Processing: \(viewModel.patientModel.fullName)")
                    .navigationBarTitleDisplayMode(.inline)
                    
                    // Main content area.
                    content(for: selectedFlowStep)
                }
                .navigationViewStyle(DoubleColumnNavigationViewStyle())
            }
        }
        .onAppear {
            officeViewModel.fetchOffices()
            appointmentVM.checkForTodayClinic()
        }
        // PDF Preview Sheet.
        .sheet(isPresented: $showPDFPreview) {
            if let pdfDocument = pdfDocument {
                PDFPreviewView(pdfDocument: pdfDocument, onUpload: {
                    handleUpload()
                    return .success(())
                })
            } else {
                Text("Error generating PDF.")
            }
        }
        // Address Picker Sheet.
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
    }
    
    // MARK: - Main Content for Each Step
    @ViewBuilder
    private func content(for step: PatientFlowStep) -> some View {
        switch step {
        case .basicInfo:
            VStack {
                BasicInfoStepView(
                    email: $viewModel.patientModel.email,
                    firstName: $viewModel.patientModel.firstName,
                    lastName: $viewModel.patientModel.lastName,
                    dob: $viewModel.patientModel.dob,
                    age: $viewModel.patientModel.age,
                    phone: $viewModel.patientModel.phone,
                    reasonForVisit: $viewModel.patientModel.reasonForVisit,
                    isExistingPatient: $viewModel.patientModel.isExistingPatient,
                    initialDate: viewModel.patientModel.dateOfBirth,
                    isWalkIn: isWalkIn
                )
                nextButton(currentStep: .basicInfo, nextStep: .demographics, isComplete: isBasicInfoComplete)
            }
        case .demographics:
            VStack {
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
                nextButton(currentStep: .demographics, nextStep: .signature, isComplete: isDemographicsComplete)
            }
        case .signature:
            VStack {
                SignatureStep(signatureImage: $viewModel.patientModel.signatureImage)
                    .padding(.horizontal, 20)
                nextButton(currentStep: .signature, nextStep: .uploadDoc, isComplete: isSignatureComplete)
            }
        case .uploadDoc:
            // UPDATED: Instead of finishing the flow, mark upload doc as complete and navigate to vitals.
            CheckInDocumentView(
                onFinish: {
                    isUploadDocComplete = true
                    selectedFlowStep = .vitals
                },
                onPreviewPDF: { previewPDFAction() }
            )
        case .vitals:
            VitalsStepView(onComplete: {
                // After vitals, finish the flow (customize as needed)
                viewModel.resetPatientData()
                inPatientFlow = false
            }, patientModel: viewModel.patientModel)
        }
    }
    
    // MARK: - Next Button Helper
    private func nextButton(currentStep: PatientFlowStep, nextStep: PatientFlowStep, isComplete: Bool) -> some View {
        Button(action: {
            selectedFlowStep = nextStep
        }) {
            Text("Next")
                .frame(maxWidth: .infinity)
                .padding()
                .background(isComplete ? UMSSBrand.gold : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(8)
        }
        .disabled(!isComplete)
        .padding()
    }
    
    // MARK: - Appointment Handling
    private func handleAppointmentSelection(_ appointment: Appointment) {
        // For booked appointments with existing patient data, load and jump to signature.
        if appointment.booked == true && !appointment.patientId.isEmpty {
            isLoadingPatientData = true
            viewModel.patientModel.appointmentId = appointment.id
            isWalkIn = false  // set for booked appointments
            viewModel.fetchPatientData(patientId: appointment.patientId) { success in
                DispatchQueue.main.async {
                    self.isLoadingPatientData = false
                    if success {
                        withAnimation {
                            inPatientFlow = true
                            selectedFlowStep = .signature
                        }
                    } else {
                        // Handle error – e.g., show an alert.
                    }
                }
            }
        } else {
            // For walk-ins or new appointments, reset and start at basic info.
            viewModel.patientModel.appointmentId = appointment.id
            viewModel.resetPatientData()
            isWalkIn = true  // set for walk-in appointments
            inPatientFlow = true
            selectedFlowStep = .basicInfo
        }
    }
    
    // MARK: - PDF Preview and Upload Functions
    private func previewPDFAction() {
        isGeneratingPDF = true
        
        // First ensure we have a token before attempting to generate the PDF
        if accessToken == nil {
            getAccessToken { token in
                guard let token = token else {
                    DispatchQueue.main.async {
                        self.isGeneratingPDF = false
                        print("Failed to get access token")
                    }
                    return
                }
                
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
        guard let _ = accessToken else {
            isGeneratingPDF = false
            print("No access token available for PDF generation")
            return
        }
        
        let generatedPDF = viewModel.generateFilledPDF()
        
        // Only show PDF preview if we have a valid PDF document
        if let pdf = generatedPDF, pdf.pageCount > 0 {
            self.pdfDocument = generatedPDF
            isGeneratingPDF = false
            showPDFPreview = true
        } else {
            isGeneratingPDF = false
            print("Failed to generate valid PDF")
        }
    }
    
    private func handleUpload() {
        guard let pdfDocument = pdfDocument,
              let pdfData = pdfDocument.dataRepresentation() else {
            uploadStatus = "Failed to get PDF data."
            return
        }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm"
        let timestamp = dateFormatter.string(from: Date())
        let patientName = "\(viewModel.patientModel.firstName)_\(viewModel.patientModel.lastName)"
            .replacingOccurrences(of: " ", with: "_")
        let fileName = "UMSS_Intake_\(timestamp)_\(patientName).pdf"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        do {
            try pdfData.write(to: tempURL)
        } catch {
            uploadStatus = "Failed to write PDF: \(error.localizedDescription)"
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

//
// MARK: - Dashboard and Document Upload Views
//

struct DashboardView: View {
    @ObservedObject var appointmentVM: AppointmentViewModel
    let handleWalkIn: () -> Void
    let handleAppointment: (Appointment) -> Void
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                HeaderView()
                Text("Let's Begin!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(UMSSBrand.navy)
                
                if appointmentVM.isLoading {
                    ProgressView("Checking today's clinic schedule...")
                } else if let errorMessage = appointmentVM.errorMessage {
                    Text("Error: \(errorMessage)")
                        .foregroundColor(.red)
                } else if !appointmentVM.isClinicDay {
                    Text("Today is not a scheduled clinic day.")
                        .font(.headline)
                        .foregroundColor(.secondary)
                } else if let _ = appointmentVM.todaysOffice {
                    VStack(alignment: .leading, spacing: 15) {
                        if appointmentVM.appointments.isEmpty {
                            Text("No appointments available")
                                .foregroundColor(.secondary)
                        } else {
                            AppointmentListView(
                                appointments: appointmentVM.appointments,
                                onAppointmentSelected: handleAppointment
                            )
                        }
                    }
                    .padding()
                }
                
            }
            .padding()
        }
    }
}

struct CheckInDocumentView: View {
    // Callbacks for finishing the flow or previewing the PDF.
    let onFinish: () -> Void
    let onPreviewPDF: () -> Void

    // Add state to track if PDF has been previewed.
    @State private var hasPreviewedPDF = false

    var body: some View {
        VStack(spacing: 20) {
            HeaderView()
                .padding(.bottom, 20)

            Text("Document Preview")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(UMSSBrand.navy)

            Text("Review your completed document before proceeding.")
                .font(.system(size: 16))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Spacer()

            // Preview PDF Button
            Button(action: {
                onPreviewPDF()
                hasPreviewedPDF = true
            }) {
                HStack {
                    Image(systemName: "doc.text.viewfinder")
                    Text("Preview PDF")
                }
                .font(.headline)
                .padding()
                .frame(maxWidth: .infinity)
                .background(UMSSBrand.navy)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .padding(.horizontal)

            // New "Next" button, disabled until PDF is previewed
            Button(action: onFinish) {
                Text("Next")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(hasPreviewedPDF ? UMSSBrand.gold : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
            .disabled(!hasPreviewedPDF)

            Spacer()
        }
        .padding()
        .background(Color(UIColor.systemGroupedBackground).edgesIgnoringSafeArea(.all))
    }
}
