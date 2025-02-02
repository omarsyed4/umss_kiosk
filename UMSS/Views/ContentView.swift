//
//  ContentView.swift
//  UMSS
//
//  Created by Omar Syed on 1/29/25.
//

import SwiftUI
import PDFKit

struct ContentView: View {
    @StateObject private var viewModel = PatientFormViewModel()
    @State private var showPDFPreview = false
    @State private var pdfDocument: PDFDocument?
    @State private var currentStep: Int = 0
    @State private var isAddressPickerPresented = false

    private let incomeOptions = [
        "1 Person - $2430 or Less",
        "2 Persons - $3287 or Less",
        "3 Persons - $4143 or Less",
        "4 Persons - $5000 or Less",
        "Zero - No Income",
        "Other"
    ]
    
    private var totalSteps: Int { 10 }
    
    var body: some View {
        NavigationView {
            VStack {
                Spacer()
                
                Text("Step \(currentStep + 1) of \(totalSteps)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding(.bottom, 10)
                
                Group {
                    if currentStep == 0 {
                        VStack(spacing: 20) {
                            Text("Let's Begin!")
                                .font(.largeTitle)
                                .bold()
                            Text("Welcome to the intake process. Tap Next to get started.")
                                .multilineTextAlignment(.center)
                        }
                        .transition(.move(edge: .trailing))
                        
                    } else if currentStep == 1 {
                        StepView(question: "What is your email?",
                                 placeholder: "Email",
                                 text: $viewModel.patientForm.email)
                            .transition(.move(edge: .trailing))
                        
                    } else if currentStep == 2 {
                        StepView(question: "What is your first name?",
                                 placeholder: "First Name",
                                 text: $viewModel.patientForm.firstName)
                            .transition(.move(edge: .trailing))
                        
                    } else if currentStep == 3 {
                        StepView(question: "What is your last name?",
                                 placeholder: "Last Name",
                                 text: $viewModel.patientForm.lastName)
                            .transition(.move(edge: .trailing))
                        
                    } else if currentStep == 4 {
                        StepView(question: "What is your phone number?",
                                 placeholder: "Phone Number",
                                 text: $viewModel.patientForm.phoneNumber)
                            .transition(.move(edge: .trailing))
                        
                    } else if currentStep == 5 {
                        StepView(question: "What is your date of birth?",
                                 placeholder: "DOB",
                                 text: $viewModel.patientForm.dob)
                            .transition(.move(edge: .trailing))
                        
                    } else if currentStep == 6 {
                        AddressStepView(address: $viewModel.patientForm.address,
                                        isPickerPresented: $isAddressPickerPresented)
                            .transition(.move(edge: .trailing))
                        
                    } else if currentStep == 7 {
                        StepView(question: "What is your race?",
                                 placeholder: "Race",
                                 text: $viewModel.patientForm.race)
                            .transition(.move(edge: .trailing))
                        
                    } else if currentStep == 8 {
                        StepView(question: "What is your ethnicity?",
                                 placeholder: "Ethnicity",
                                 text: $viewModel.patientForm.ethnicity)
                            .transition(.move(edge: .trailing))
                        
                    } else if currentStep == 9 {
                        VStack(spacing: 20) {
                            Text("What is your monthly income?")
                                .font(.title)
                            Picker("Monthly Income", selection: $viewModel.patientForm.monthlyIncome) {
                                ForEach(incomeOptions, id: \.self) { option in
                                    Text(option).tag(option)
                                }
                            }
                            .pickerStyle(WheelPickerStyle())
                        }
                        .transition(.move(edge: .trailing))
                    }
                }
                .animation(.easeInOut, value: currentStep)
                
                Spacer()
                
                HStack {
                    if currentStep > 0 {
                        Button("Back") {
                            withAnimation { currentStep -= 1 }
                        }
                        .padding(.horizontal)
                    }
                    
                    Spacer()
                    
                    if currentStep < totalSteps - 1 {
                        Button("Next") {
                            withAnimation { currentStep += 1 }
                        }
                        .padding(.horizontal)
                    } else {
                        Button("Preview PDF") {
                            DispatchQueue.main.async {
                                print("[DEBUG] ContentView: Generating PDF with address: \(viewModel.patientForm.address)")
                                pdfDocument = viewModel.generateFilledPDF()
                                if pdfDocument == nil {
                                    print("[ERROR] pdfDocument is nil after generation!")
                                } else {
                                    print("[DEBUG] pdfDocument successfully generated. Showing preview...")
                                }
                                showPDFPreview = true
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .font(.headline)
                .padding(.vertical)
            }
            .padding()
            .navigationTitle("Intake Form")
            .sheet(isPresented: $showPDFPreview) {
                if let pdfDocument = pdfDocument {
                    PDFPreviewView(pdfDocument: pdfDocument)
                } else {
                    Text("Error generating PDF.")
                }
            }
            .sheet(isPresented: $isAddressPickerPresented) {
                GoogleAddressAutocompleteView(address: $viewModel.patientForm.address,
                                              isPresented: $isAddressPickerPresented)
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

// A helper view for individual text-input steps.
struct StepView: View {
    let question: String
    let placeholder: String
    @Binding var text: String

    var body: some View {
        VStack(spacing: 20) {
            Text(question)
                .font(.title)
                .multilineTextAlignment(.center)
            TextField(placeholder, text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
                .font(.body)
        }
    }
}

// A specialized view for the address step that uses Google Places autocomplete.
struct AddressStepView: View {
    @Binding var address: String
    @Binding var isPickerPresented: Bool
    @State private var previousAddress: String = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text("What is your address?")
                .font(.title)
                .multilineTextAlignment(.center)
            
            Button(action: {
                print("[DEBUG] AddressStepView: Button tapped. isPickerPresented is set to true.")
                isPickerPresented = true
            }) {
                if address.isEmpty {
                    Text("Tap to select your address")
                        .foregroundColor(.blue)
                        .underline()
                        .onAppear {
                            print("[DEBUG] AddressStepView: Button showing because address is empty.")
                        }
                } else {
                    VStack {
                        Text("Selected Address:")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text(address)
                            .font(.body)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .onAppear {
                        print("[DEBUG] AddressStepView: Displaying selected address: \(address)")
                    }
                }
            }
        }
        .onAppear {
            print("[DEBUG] AddressStepView: View appeared with address: \(address)")
            previousAddress = address
        }
        .onChange(of: address) { newValue in
            print("[DEBUG] AddressStepView: Address changed from: \(previousAddress) to: \(newValue)")
            previousAddress = newValue
        }
    }
}
