import SwiftUI

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
            
            Spacer()
        }
        .padding()
        .alert(isPresented: $showConfirmation) {
            Alert(
                title: Text(isSuccess ? "Success" : "Error"),
                message: Text(isSuccess ? 
                              "Patient has been sent to the doctor." : 
                              "Failed to send patient to doctor. Please try again."),
                dismissButton: .default(Text("OK")) {
                    if isSuccess {
                        onComplete()
                    }
                }
            )
        }
        .onAppear {
            print("DoctorSelectView appeared with \(providers.count) providers")
            for (index, provider) in providers.enumerated() {
                print("Provider \(index+1): \(provider.name) (\(provider.specialty)) - ID: \(provider.id)")
            }
        }
    }
    
    private func sendToDoctor() {
        guard let providerId = selectedProviderId else { return }
        
        isProcessing = true
        errorMessage = nil
        
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
}

