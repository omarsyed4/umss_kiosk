import SwiftUI
import FirebaseFirestore

struct DoctorSelectView: View {
    let patientName: String
    let appointmentId: String
    let providers: [Provider]
    let appointmentVM: AppointmentViewModel
    let onComplete: () -> Void
    
    @State private var selectedProviderId: String? = nil
    @State private var isProcessing = false
    @State private var showConfirmation = false
    @State private var errorMessage: String? = nil
    @State private var isSuccess = false
    @State private var patientSentToDoctor = false
    @State private var canMarkAsSeen = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Send Patient to Doctor")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(UMSSBrand.navy)
            
            Text("Patient: \(patientName)")
                .font(.headline)
                .padding(.bottom, 10)
            
            if providers.isEmpty {
                VStack(spacing: 15) {
                    Text("No providers available today")
                        .foregroundColor(.red)
                        .padding()
                    
                    if let errorMessage = appointmentVM.errorMessage {
                        Text("Error: \(errorMessage)")
                            .foregroundColor(.red)
                            .font(.footnote)
                            .padding(.horizontal)
                    }
                    
                    Button(action: {
                        // Attempt to refresh providers list
                        appointmentVM.checkForTodayClinic()
                    }) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("Refresh Providers")
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    
                    Button(action: onComplete) {
                        Text("Return to Dashboard")
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(UMSSBrand.gold)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                }
            } else {
                Text("Select a provider:")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                                
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(providers) { provider in
                            ChoiceRow(
                                title: "\(provider.name) - \(provider.specialty)",
                                isSelected: selectedProviderId == provider.id,
                                action: {
                                    selectedProviderId = provider.id
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                }
                
                if canMarkAsSeen {
                    // Show button to mark patient as seen by doctor
                    Button(action: markPatientAsSeen) {
                        if isProcessing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        } else {
                            Text("Mark as Seen by Doctor")
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(UMSSBrand.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .disabled(isProcessing)
                    .padding(.horizontal)
                } else {
                    // Show button to send patient to doctor
                    Button(action: sendToDoctor) {
                        if isProcessing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        } else {
                            Text("Send to Doctor")
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(selectedProviderId == nil ? Color.gray : UMSSBrand.gold)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .disabled(selectedProviderId == nil || isProcessing)
                    .padding(.horizontal)
                }
            }
            
            Spacer()
        }
        .padding()
        .alert(isPresented: $showConfirmation) {
            Alert(
                title: Text(isSuccess ? "Success" : "Error"),
                message: Text(isSuccess ? 
                              (patientSentToDoctor ? "Patient has been sent to the doctor." : "Patient has been marked as seen by the doctor.") : 
                              (patientSentToDoctor ? "Failed to send patient to doctor. Please try again." : "Failed to mark patient as seen. Please try again.")),
                dismissButton: .default(Text("OK")) {
                    if isSuccess {
                        if !patientSentToDoctor {
                            // If marking as seen was successful, return to dashboard
                            onComplete()
                        } else {
                            // If sending to doctor was successful, show the mark as seen button
                            canMarkAsSeen = true
                        }
                    }
                }
            )
        }
        .onAppear {
            print("DoctorSelectView appeared with \(providers.count) providers")
            for (index, provider) in providers.enumerated() {
                print("Provider \(index+1): \(provider.name) (\(provider.specialty)) - ID: \(provider.id)")
            }
            
            // Check if this patient has already been sent to a doctor
            checkPatientStatus()
            
            // If the patient has already seen the doctor, mark the step as complete
            if let officeId = appointmentVM.selectedOfficeId {
                let db = Firestore.firestore()
                db.collection("offices")
                    .document(officeId)
                    .collection("appointments")
                    .document(appointmentId)
                    .getDocument { snapshot, error in
                        if let error = error {
                            print("Error checking seenDoctor status: \(error.localizedDescription)")
                            return
                        }
                        
                        guard let snapshot = snapshot, snapshot.exists,
                              let data = snapshot.data() else {
                            return
                        }
                        
                        if let seenDoctor = data["seenDoctor"] as? Bool, seenDoctor {
                            // Patient has already seen the doctor, mark as complete
                            DispatchQueue.main.async {
                                self.canMarkAsSeen = false
                                self.patientSentToDoctor = true
                            }
                        }
                    }
            }
        }
    }
    
    private func checkPatientStatus() {
        guard !appointmentId.isEmpty else { return }
        
        if let officeId = appointmentVM.selectedOfficeId {
            let db = Firestore.firestore()
            let appointmentRef = db.collection("offices")
                .document(officeId)
                .collection("appointments")
                .document(appointmentId)
            
            appointmentRef.getDocument { snapshot, error in
                if let error = error {
                    print("Error checking patient status: \(error.localizedDescription)")
                    return
                }
                
                guard let snapshot = snapshot, snapshot.exists,
                      let data = snapshot.data() else {
                    print("No appointment data found")
                    return
                }
                
                if let sentToDoctor = data["sentToDoctor"] as? Bool, sentToDoctor,
                   let providerId = data["assignedProviderId"] as? String {
                    // Patient has already been sent to a doctor
                    DispatchQueue.main.async {
                        self.selectedProviderId = providerId
                        self.patientSentToDoctor = true
                        self.canMarkAsSeen = true
                    }
                }
            }
        }
    }
    
    private func sendToDoctor() {
        guard let providerId = selectedProviderId else { return }
        
        isProcessing = true
        errorMessage = nil
        patientSentToDoctor = true
        
        appointmentVM.sendPatientToDoctor(appointmentId: appointmentId, providerId: providerId) { success in
            DispatchQueue.main.async {
                isProcessing = false
                isSuccess = success
                showConfirmation = true
                
                if !success {
                    errorMessage = "Failed to assign doctor. Please try again."
                }
            }
        }
    }
    
    private func markPatientAsSeen() {
        isProcessing = true
        errorMessage = nil
        patientSentToDoctor = false
        
        appointmentVM.updateSeenDoctorStatus(appointmentId: appointmentId) { success in
            DispatchQueue.main.async {
                isProcessing = false
                isSuccess = success
                showConfirmation = true
                
                if !success {
                    errorMessage = "Failed to mark patient as seen. Please try again."
                }
            }
        }
    }
}

