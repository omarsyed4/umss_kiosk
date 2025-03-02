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
    // Patient flow pages (dashboard is separate)
    enum PatientFlowStep: String, CaseIterable, Identifiable {
        case basicInfo = "Basic Info"
        case demographics = "Demographics"
        case signature = "Signature"
        case thankYou = "Thank You"
        
        var id: Self { self }
    }
    
    // MARK: - State Variables
    // This flag determines whether we are in the patient flow (which shows a sidebar) or on the dashboard.
    @State private var inPatientFlow: Bool = false
    @State private var selectedFlowStep: PatientFlowStep = .basicInfo
    
    @StateObject private var viewModel = PatientModelViewModel()
    @StateObject private var appointmentVM = AppointmentViewModel()
    @StateObject private var officeViewModel = OfficeViewModel()
    
    // PDF and upload states
    @State private var showPDFPreview = false
    @State private var isGeneratingPDF = false
    @State private var pdfDocument: PDFDocument?
    @State private var accessToken: String?
    @State private var uploadStatus: String = ""
    
    // Additional states
    @State private var isAddressPickerPresented = false
    @State private var isLoadingPatientData = false
    
    // Folder ID for Drive uploads
    let folderID = "16b3ZeFMpHft5yN8zGguhABeNjgrTa6Mu"
    
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
                // Patient Flow – show a NavigationView with a sidebar for the patient flow steps.
                NavigationView {
                    List(PatientFlowStep.allCases, id: \.self) { step in
                        Button(action: { selectedFlowStep = step }) {
                            Text(step.rawValue)
                        }
                    }
                    .listStyle(SidebarListStyle())
                    .navigationTitle("Patient Flow")
                    
                    // Main content area
                    content(for: selectedFlowStep)
                }
                .navigationViewStyle(DoubleColumnNavigationViewStyle())            }
        }
        .onAppear {
            officeViewModel.fetchOffices()
            appointmentVM.checkForTodayClinic()
        }
        // PDF Preview Sheet
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
        // Address Picker Sheet
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
    
    // Returns the view for each patient flow step.
    @ViewBuilder
    private func content(for step: PatientFlowStep) -> some View {
        switch step {
        case .basicInfo:
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
        case .demographics:
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
        case .signature:
            SignatureStep(signatureImage: $viewModel.patientModel.signatureImage)
                .padding(.horizontal, 20)
        case .thankYou:
            // When finished, the Thank You view calls the onFinish callback to return to the dashboard.
            ThankYouView(onFinish: { inPatientFlow = false },
                         onPreviewPDF: { previewPDFAction() })
        }
    }
    
    // MARK: - Appointment Handling
    private func handleAppointmentSelection(_ appointment: Appointment) {
        // For booked appointments with existing patient data, load the patient info then jump to the signature step.
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
                        // Handle error – for example, show an alert.
                    }
                }
            }
        } else {
            // For walk-ins or new appointments, reset and start at the basic info step.
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
    // Added onPreviewPDF callback property.
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
            // New Preview PDF button
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