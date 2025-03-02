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
        case thankYou = "Thank You"
        
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
    
    // Folder ID for Drive uploads.
    let folderID = "16b3ZeFMpHft5yN8zGguhABeNjgrTa6Mu"
    
    // MARK: - Computed Validation Properties
    private var isBasicInfoComplete: Bool {
        let model = viewModel.patientModel
        return !model.email.trimmingCharacters(in: .whitespaces).isEmpty &&
               !model.firstName.trimmingCharacters(in: .whitespaces).isEmpty &&
               !model.lastName.trimmingCharacters(in: .whitespaces).isEmpty &&
               !model.dob.trimmingCharacters(in: .whitespaces).isEmpty &&
               !model.age.trimmingCharacters(in: .whitespaces).isEmpty &&
               !model.phone.trimmingCharacters(in: .whitespaces).isEmpty &&
               !model.reasonForVisit.trimmingCharacters(in: .whitespaces).isEmpty
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
                    steps.append(.thankYou)
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
                            HStack {
                                // Icon for each step.
                                Group {
                                    switch step {
                                    case .basicInfo:
                                        Image(systemName: "person.fill")
                                    case .demographics:
                                        Image(systemName: "info.circle.fill")
                                    case .signature:
                                        Image(systemName: "pencil.circle.fill")
                                    case .thankYou:
                                        Image(systemName: "checkmark.seal.fill")
                                    }
                                }
                                .frame(width: 24)
                                
                                Text(step.rawValue)
                                
                                Spacer()
                                // Show a checkmark if the step is complete.
                                if (step == .basicInfo && isBasicInfoComplete) ||
                                   (step == .demographics && isDemographicsComplete) ||
                                   (step == .signature && isSignatureComplete) {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.green)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                // Only allow navigating to a step if it is allowed (or if it’s a previous step).
                                let allSteps = PatientFlowStep.allCases
                                if let tappedIndex = allSteps.firstIndex(of: step),
                                   let currentIndex = allSteps.firstIndex(of: selectedFlowStep),
                                   tappedIndex <= currentIndex || allowedSteps.contains(step) {
                                    selectedFlowStep = step
                                }
                            }
                            .disabled(!(allowedSteps.contains(step) || step == .basicInfo))
                        }
                        Spacer()
                        // Cancel button to reset patient data and return to dashboard.
                        Button(action: {
                            viewModel.resetPatientData()
                            inPatientFlow = false
                        }) {
                            HStack {
                                Image(systemName: "xmark.circle.fill")
                                Text("Cancel")
                            }
                            .foregroundColor(.red)
                            .padding()
                        }
                    }
                    .frame(minWidth: 250)
                    .listStyle(SidebarListStyle())
                    .navigationTitle("Patient Flow")
                    
                    // Main content area.
                    content(for: selectedFlowStep)
//                        .toolbar {
//                            ToolbarItem(placement: .navigationBarLeading) {
//                                Button("Dashboard") {
//                                    inPatientFlow = false
//                                }
//                            }
//                        }
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
                    initialDate: viewModel.patientModel.dateOfBirth
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
                nextButton(currentStep: .signature, nextStep: .thankYou, isComplete: isSignatureComplete)
            }
        case .thankYou:
            // Thank You view offers a Preview PDF button and a Return to Dashboard option.
            ThankYouView(
                onFinish: {
                    viewModel.resetPatientData()
                    inPatientFlow = false
                },
                onPreviewPDF: { previewPDFAction() }
            )
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
            inPatientFlow = true
            selectedFlowStep = .basicInfo
        }
    }
    
    // MARK: - PDF Preview and Upload Functions
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
        let generatedPDF = viewModel.generateFilledPDF()
        self.pdfDocument = generatedPDF
        isGeneratingPDF = false
        showPDFPreview = true
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
// MARK: - Dashboard and Thank You Views
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
                
                // Walk-In button to start a new patient flow.
                Button(action: handleWalkIn) {
                    Text("Walk-In")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(UMSSBrand.gold)
                        .cornerRadius(8)
                }
            }
            .padding()
        }
    }
}

struct ThankYouView: View {
    // Callbacks for finishing the flow or previewing the PDF.
    let onFinish: () -> Void
    let onPreviewPDF: () -> Void
    
    var body: some View {
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
            Button("Preview PDF", action: onPreviewPDF)
                .font(.headline)
                .padding()
                .background(UMSSBrand.navy)
                .foregroundColor(.white)
                .cornerRadius(8)
            Button("Return to Dashboard", action: onFinish)
                .font(.headline)
                .padding()
                .background(UMSSBrand.gold)
                .foregroundColor(.white)
                .cornerRadius(8)
        }
        .padding()
    }
}
