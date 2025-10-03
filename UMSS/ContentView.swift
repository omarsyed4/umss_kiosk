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
        case viewVitals = "View Vitals" // New step for viewing vitals
        case doctorSelect = "Doctor Selection"
        
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
    @State private var isDoctorSelectComplete: Bool = false // NEW doctor selection completion state
    
    // Add validation override flags for already checked-in patients
    @State private var bypassBasicInfoValidation: Bool = false
    @State private var bypassDemographicsValidation: Bool = false 
    @State private var bypassSignatureValidation: Bool = false
    
    // Add state for showing vitals display
    @State private var vitalsData: [String: Any]? = nil
    
    // MARK: - Computed Validation Properties
    private var isBasicInfoComplete: Bool {
        // If bypass flag is set, return true without validation
        if bypassBasicInfoValidation {
            return true
        }
        
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
        // If bypass flag is set, return true without validation
        if bypassDemographicsValidation {
            return true
        }
        
        let model = viewModel.patientModel
        return !model.selectedGender.trimmingCharacters(in: .whitespaces).isEmpty &&
               !model.selectedRace.trimmingCharacters(in: .whitespaces).isEmpty &&
               !model.selectedMaritalStatus.trimmingCharacters(in: .whitespaces).isEmpty &&
               !model.selectedEthnicity.trimmingCharacters(in: .whitespaces).isEmpty &&
               !model.selectedIncome.trimmingCharacters(in: .whitespaces).isEmpty &&
               !model.address.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    private var isSignatureComplete: Bool {
        // If bypass flag is set, return true without validation
        if bypassSignatureValidation {
            return true
        }
        
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
                        if isVitalsComplete {
                            // Add viewVitals step when vitals are complete
                            steps.append(.viewVitals)
                            steps.append(.doctorSelect)
                        }
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
                    sidebarView
                    
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
            CheckInDocumentView(
                onFinish: {
                    isUploadDocComplete = true
                    updateCheckInStatus()
                    selectedFlowStep = .vitals
                },
                onPreviewPDF: { previewPDFAction() },
                isGeneratingPDF: isGeneratingPDF
            )
        case .vitals:
            VitalsStepView(onComplete: { vitalsData in
                // Update vitals status in Firebase if we have an appointment ID
                if !viewModel.patientModel.appointmentId.isEmpty {
                    appointmentVM.updateVitalsStatus(appointmentId: viewModel.patientModel.appointmentId, vitalsData: vitalsData) { success in
                        if success {
                            print("Vitals status and data updated successfully in Firebase")
                        } else {
                            print("Failed to update vitals status and data in Firebase")
                        }
                    }
                } else {
                    print("No appointment ID available to update vitals status")
                }
                
                appointmentVM.checkForTodayClinic() // Refresh providers list
                isVitalsComplete = true
                selectedFlowStep = .viewVitals
            }, patientModel: viewModel.patientModel)
        case .viewVitals:
            if let vitalsData = vitalsData {
                VitalsDisplayView(vitalsData: vitalsData)
                    .onAppear {
                        // Fetch vitals data if not already loaded
                        if vitalsData == nil {
                            fetchVitalsData()
                        }
                    }
            } else {
                VStack {
                    Text("Loading vitals data...")
                        .font(.title)
                        .foregroundColor(.secondary)
                    ProgressView()
                        .padding()
                    
                    Button("Refresh") {
                        fetchVitalsData()
                    }
                    .padding()
                }
                .padding()
                .onAppear {
                    fetchVitalsData()
                }
            }
        case .doctorSelect:
            DoctorSelectView(
                patientName: viewModel.patientModel.fullName,
                appointmentId: viewModel.patientModel.appointmentId,
                providers: appointmentVM.providers,
                appointmentVM: appointmentVM,
                onComplete: {
                    isDoctorSelectComplete = true
                    viewModel.resetPatientData()
                    inPatientFlow = false
                }
            )
        }
    }
    
    // MARK: - Sidebar View
    private var sidebarView: some View {
        VStack(alignment: .leading) {
            List {
                // Flow step options
                ForEach(PatientFlowStep.allCases, id: \.self) { step in
                    // Hide viewVitals from the main list as we'll handle it separately
                    if step != .viewVitals {
                        let isEnabled = (allowedSteps.contains(step) || step == .basicInfo)
                        // Determine if step should be shown as completed but inaccessible
                        let isCompletedButInaccessible = isVitalsComplete && 
                            (step == .basicInfo || step == .demographics || 
                             step == .signature || step == .uploadDoc || 
                             step == .vitals || step == .doctorSelect)
                        
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
                                case .viewVitals:
                                    Image(systemName: "heart.text.square")
                                case .doctorSelect:
                                    Image(systemName: "stethoscope")
                                }
                            }
                            .frame(width: 24)
                            .foregroundColor(isCompletedButInaccessible ? .gray : .primary)
                            
                            Text(step.rawValue)
                                .strikethrough(isCompletedButInaccessible, color: .gray)
                                .foregroundColor(isCompletedButInaccessible ? .gray : (isEnabled ? .primary : .gray))
                            
                            Spacer()
                            // Show a checkmark if the step is complete.
                            if (step == .basicInfo && isBasicInfoComplete) ||
                               (step == .demographics && isDemographicsComplete) ||
                               (step == .vitals && isVitalsComplete) ||
                               (step == .uploadDoc && isUploadDocComplete) ||
                               (step == .signature && isSignatureComplete) ||
                               (step == .doctorSelect && isDoctorSelectComplete) {
                                Image(systemName: "checkmark.rectangle.fill")
                                    .foregroundColor(.green)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            // Only allow navigating if it's not a completed but inaccessible step
                            if !isCompletedButInaccessible {
                                // Only allow navigating to a step if it is allowed (or if it's a previous step).
                                let allSteps = PatientFlowStep.allCases
                                if let tappedIndex = allSteps.firstIndex(of: step),
                                   let currentIndex = allSteps.firstIndex(of: selectedFlowStep),
                                   tappedIndex <= currentIndex || isEnabled {
                                    selectedFlowStep = step
                                }
                            }
                        }
                        .disabled(!isEnabled || isCompletedButInaccessible)
                        .foregroundColor(isEnabled && !isCompletedButInaccessible ? .primary : .gray)
                    }
                }
            }
            .listStyle(SidebarListStyle())
            
            Spacer()
            
            
            // Conditional button - either "Back to Dashboard" or "Cancel"
            Button(action: {
                if isBasicInfoComplete && isDemographicsComplete {
                    // Refresh dashboard data before returning
                    appointmentVM.checkForTodayClinic()
                    // Just return to dashboard without resetting data
                    inPatientFlow = false
                } else {
                    // Reset patient data and return to dashboard
                    viewModel.resetPatientData()
                    // Refresh dashboard data
                    appointmentVM.checkForTodayClinic()
                    inPatientFlow = false
                }
            }) {
                HStack {
                    if isBasicInfoComplete && isDemographicsComplete {
                        Image(systemName: "house")
                        Text("Back to Dashboard")
                            .foregroundColor(.blue)
                    } else {
                        Image(systemName: "xmark.bin")
                            .foregroundColor(.red)
                        Text("Cancel")
                            .foregroundColor(.red)
                    }
                }
                .padding()
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .frame(minWidth: 250)
        .navigationTitle("Processing: \(viewModel.patientModel.fullName)")
        .navigationBarTitleDisplayMode(.inline)
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
        if appointment.booked == true && !appointment.patientId.isEmpty {
            // Before loading new patient data, reset state to avoid data transfer
            vitalsData = nil
            
            isLoadingPatientData = true
            viewModel.patientModel.appointmentId = appointment.id
            isWalkIn = false
            viewModel.fetchPatientData(patientId: appointment.patientId) { success in
                DispatchQueue.main.async {
                    self.isLoadingPatientData = false
                    if success {
                        if appointment.isCheckedIn {
                            // Set bypass flags instead of trying to directly assign computed properties
                            self.bypassBasicInfoValidation = true
                            self.bypassDemographicsValidation = true
                            self.bypassSignatureValidation = true
                            self.isUploadDocComplete = true
                            
                            // Set vitals complete state based on appointment record
                            self.isVitalsComplete = appointment.vitalsDone ?? false
                            
                            // If vitals are done and patient has seen doctor, mark doctor selection as complete too
                            if appointment.vitalsDone == true && appointment.seenDoctor == true {
                                self.isDoctorSelectComplete = true
                            }
                            
                            self.selectedFlowStep = appointment.vitalsDone ?? false ? .viewVitals : .vitals
                        }
                        withAnimation {
                            inPatientFlow = true
                            if !appointment.isCheckedIn {
                                selectedFlowStep = .signature
                            }
                        }
                    } else {
                        // Handle error
                    }
                }
            }
        } else {
            // For walk-ins: Reset all states first
            viewModel.resetPatientData()
            
            // Clear all state variables to prevent data transfer
            vitalsData = nil
            isVitalsComplete = false
            isUploadDocComplete = false
            isDoctorSelectComplete = false
            bypassBasicInfoValidation = false
            bypassDemographicsValidation = false
            bypassSignatureValidation = false
            
            // Then set the new appointment ID and walk-in flag
            viewModel.patientModel.appointmentId = appointment.id
            isWalkIn = true
            inPatientFlow = true
            selectedFlowStep = .basicInfo
        }
    }

    // MARK: - PDF Preview and Upload Functions
    private func previewPDFAction() {
        isGeneratingPDF = true
        
        // Enhanced debugging for service account file
        print("=== Service Account File Debug ===")
        if let path = Bundle.main.path(forResource: "ServiceAccount", ofType: "json") {
            print("✅ ServiceAccount.json found at: \(path)")
            
            // Check if file is readable
            if FileManager.default.isReadableFile(atPath: path) {
                print("✅ File is readable")
                
                // Check file size
                if let attributes = try? FileManager.default.attributesOfItem(atPath: path),
                   let size = attributes[.size] as? Int64 {
                    print("✅ File size: \(size) bytes")
                }
            } else {
                print("❌ File exists but is not readable")
            }
        } else {
            print("❌ ServiceAccount.json not found in bundle!")
            
            // List all JSON files in bundle
            if let bundlePath = Bundle.main.resourcePath {
                let files = try? FileManager.default.contentsOfDirectory(atPath: bundlePath)
                let jsonFiles = files?.filter { $0.hasSuffix(".json") } ?? []
                print("JSON files in bundle: \(jsonFiles)")
                print("All files in bundle: \(files?.prefix(20) ?? [])")
            }
            
            // Check main bundle resource names
            let resourceKeys: [URLResourceKey] = [.nameKey, .isRegularFileKey]
            if let resourceURL = Bundle.main.resourceURL,
               let enumerator = FileManager.default.enumerator(
                at: resourceURL,
                includingPropertiesForKeys: resourceKeys,
                options: [.skipsHiddenFiles]
               ) {
                let allResources = enumerator.compactMap { $0 as? URL }
                    .filter { url in
                        guard let resourceValues = try? url.resourceValues(forKeys: Set(resourceKeys)),
                              let isRegularFile = resourceValues.isRegularFile else { return false }
                        return isRegularFile
                    }
                    .map { $0.lastPathComponent }
                
                let jsonResources = allResources.filter { $0.hasSuffix(".json") }
                print("All JSON resources found: \(jsonResources)")
            }
        }
        print("=== End Debug ===")
        
        if accessToken == nil {
            getAccessToken { token in
                guard let token = token else {
                    DispatchQueue.main.async {
                        self.isGeneratingPDF = false
                        self.uploadStatus = "Failed to get access token - check ServiceAccount.json file"
                        print("Failed to get access token")
                    }
                    return
                }
                DispatchQueue.main.async {
                    self.accessToken = token
                    self.generatePDF()
                }
            }
        } else {
            generatePDF()
        }
    }
    
    private func generatePDF() {
        guard let _ = accessToken else {
            isGeneratingPDF = false
            print("No access token available for PDF generation")
            return
        }
        
        let generatedPDF = viewModel.generateFilledPDF()
        
        if let pdf = generatedPDF, pdf.pageCount > 0 {
            self.pdfDocument = pdf
            DispatchQueue.main.async { 
                self.isGeneratingPDF = false
                self.showPDFPreview = true
                self.isUploadDocComplete = true
                self.updateCheckInStatus()
            }
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
    
    // MARK: - Update Check-In Status
    private func updateCheckInStatus() {
        guard !viewModel.patientModel.appointmentId.isEmpty,
              let officeId = appointmentVM.selectedOfficeId else {
            print("Cannot update check-in status: Missing appointment ID or office ID")
            return
        }
        
        print("Updating check-in status for appointment: \(viewModel.patientModel.appointmentId)")
        
        let db = Firestore.firestore()
        let appointmentRef = db.collection("offices")
            .document(officeId)
            .collection("appointments")
            .document(viewModel.patientModel.appointmentId)
        
        appointmentRef.updateData([
            "isCheckedIn": true,
            "checkedInTime": Timestamp(date: Date())
        ]) { error in
            if let error = error {
                print("Error updating check-in status: \(error.localizedDescription)")
            } else {
                print("Successfully updated check-in status to true")
            }
        }
    }
    
    // MARK: - Fetch Vitals Data
    private func fetchVitalsData() {
        guard !viewModel.patientModel.appointmentId.isEmpty,
              let officeId = appointmentVM.selectedOfficeId else {
            print("Cannot fetch vitals: Missing appointment ID or office ID")
            return
        }
        
        let db = Firestore.firestore()
        let appointmentRef = db.collection("offices")
            .document(officeId)
            .collection("appointments")
            .document(viewModel.patientModel.appointmentId)
        
        appointmentRef.getDocument { (document, error) in
            if let error = error {
                print("Error fetching appointment data: \(error.localizedDescription)")
                return
            }
            
            guard let document = document, document.exists,
                  let data = document.data(),
                  let vitals = data["vitals"] as? [String: Any] else {
                print("No vitals data found in document")
                return
            }
            
            DispatchQueue.main.async {
                self.vitalsData = vitals
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
    
    // Keep timer state to refresh the view periodically
    @State private var timer: Timer? = nil
    
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
        .onAppear {
            // Add logging when the view appears
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "M-d-yy"
            let todayString = dateFormatter.string(from: Date())
            
            let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
            let tomorrowDayId = Calendar.current.component(.weekday, from: tomorrow)
            
            print("DashboardView appeared")
            print("Current date: \(Date())")
            print("Today's date formatted for day document search: \(todayString)")
            print("Tomorrow's date: \(tomorrow)")
            print("Tomorrow's day ID: \(tomorrowDayId)")
            
            // Start a timer to update more frequently - every 10 seconds
            // This ensures any displayed times will be refreshed periodically
            self.timer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { _ in
                // Force view refresh by triggering a state change in appointmentVM
                appointmentVM.objectWillChange.send()
            }
        }
        .onDisappear {
            // Invalidate the timer when the view disappears
            self.timer?.invalidate()
            self.timer = nil
        }
    }
}


struct CheckInDocumentView: View {
    // Callbacks for finishing the flow or previewing the PDF.
    let onFinish: () -> Void
    let onPreviewPDF: () -> Void
    let isGeneratingPDF: Bool

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
                // Don't set hasPreviewedPDF here - wait for PDF to be shown
            }) {
                HStack {
                    if isGeneratingPDF { // Pass this state from ContentView
                        ProgressView()
                            .padding(.trailing, 8)
                    }
                    Image(systemName: "doc.text.viewfinder")
                    Text(isGeneratingPDF ? "Generating PDF..." : "Preview PDF")
                }
                .font(.headline)
                .padding()
                .frame(maxWidth: .infinity)
                .background(UMSSBrand.navy)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .disabled(isGeneratingPDF)
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
        .onAppear {
            // Reset preview state when view appears
            hasPreviewedPDF = false
        }
        .onChange(of: isGeneratingPDF) { newValue in
            // When PDF generation completes (goes from true to false)
            if !newValue {
                hasPreviewedPDF = true
            }
        }
    }
}
