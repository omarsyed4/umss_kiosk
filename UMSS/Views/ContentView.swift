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
    @StateObject private var viewModel = PatientFormViewModel()
    @State private var showPDFPreview = false
    @State private var pdfDocument: PDFDocument?
    @State private var currentStep: Int = 0
    @State private var moveDirection: Edge = .trailing
    @State private var isAddressPickerPresented = false

    // Adjust total steps as needed
    private var totalSteps: Int { 6 }

    var body: some View {
        NavigationView {
            ZStack {
                Color.white.ignoresSafeArea()

                VStack(spacing: 20) {
                    // Top banner
                    HeaderView()
                        .padding(.bottom, 20)

                    // A ZStack (or other container) for the step-by-step views
                    ZStack {
                        // Step 0 - "Let's Begin"
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

                        // Step 1 - Basic Info
                        } else if currentStep == 1 {
                            BasicInfoStepView(
                                email: $viewModel.patientForm.email,
                                firstName: $viewModel.patientForm.firstName,
                                lastName: $viewModel.patientForm.lastName,
                                dob: $viewModel.patientForm.dob,
                                phone: $viewModel.patientForm.phone
                            )

                        // Step 2 - Address + City/State/Zip
                        } else if currentStep == 2 {
                            AddressStepView(
                                fullAddress: $viewModel.patientForm.rawAddress,
                                streetAddress: $viewModel.patientForm.address,
                                cityStateZip: $viewModel.patientForm.cityStateZip,
                                isPickerPresented: $isAddressPickerPresented
                            )

                        // Step 3 - Gender & Race
                        } else if currentStep == 3 {
                            GenderRaceStep(
                                selectedGender: $viewModel.patientForm.selectedGender,
                                isMale: $viewModel.patientForm.isMale,
                                isFemale: $viewModel.patientForm.isFemale,
                                isWhite: $viewModel.patientForm.isWhite,
                                isBlack: $viewModel.patientForm.isBlack,
                                isAsian: $viewModel.patientForm.isAsian,
                                isAmIndian: $viewModel.patientForm.isAmIndian
                            )

                        // Step 4 - Ethnicity
                        } else if currentStep == 4 {
                            EthnicityStep(
                                isHispanic: $viewModel.patientForm.isHispanic,
                                isNonHispanic: $viewModel.patientForm.isNonHispanic
                            )

                        // Step 5 - Signature & Date
                        } else if currentStep == 5 {
                            SignatureStep(
                                signatureImage: $viewModel.patientForm.signatureImage,
                                date: $viewModel.patientForm.date
                            )
                        }
                    }
                    // Animate step changes
                    .transition(
                        .asymmetric(
                            insertion: .move(edge: moveDirection),
                            removal: .move(edge: moveDirection == .trailing ? .leading : .trailing)
                        )
                    )
                    .animation(.easeInOut, value: currentStep)

                    Spacer()

                    // Navigation Buttons
                    HStack {
                        // Back button
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

                        // Next or Preview PDF button
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
                                DispatchQueue.main.async {
                                    pdfDocument = viewModel.generateFilledPDF()
                                    showPDFPreview = true
                                }
                            }) {
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
                    .padding(.vertical, 20)
                    .padding(.horizontal)
                }
            }
            .navigationBarHidden(true)
            // Present PDF Preview
            .sheet(isPresented: $showPDFPreview) {
                if let pdfDocument = pdfDocument {
                    PDFPreviewView(pdfDocument: pdfDocument)
                } else {
                    Text("Error generating PDF.")
                }
            }
            // Present Google Places Picker
            .sheet(isPresented: $isAddressPickerPresented) {
                GoogleAddressAutocompleteView(
                    address: $viewModel.patientForm.address,
                    isPresented: $isAddressPickerPresented
                )
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

// MARK: - Sample HeaderView
struct HeaderView: View {
    var body: some View {
        VStack(spacing: 0) {
            Image("UMSS Logo")
                .resizable()
                .scaledToFit()
                .frame(width: 200, height: 200) // Adjust as needed
            Text("Your Health Matters")
                .font(.subheadline)
                .foregroundColor(UMSSBrand.navy)
        }
        .padding(.top, 20)
    }
}

// MARK: - StepView
struct StepView: View {
    let question: String
    let placeholder: String
    @Binding var text: String

    var body: some View {
        // Use a VStack that can center itself vertically
        VStack(spacing: 40) {
            
            Text(question)
                .font(.title)
                .multilineTextAlignment(.center)

            TextField(placeholder, text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .font(.body)
                .multilineTextAlignment(.leading) // or .center if you prefer
                .padding()  // Additional internal padding
                .frame(width: 600, height: 20)  // Make the field bigger
        }
        // Fill the available space, then center the VStack content
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 40) // Extra horizontal padding from edges
        .padding(.vertical, 60)  // Extra vertical spacing
    }
}

// MARK: - AddressStepView
struct AddressStepView: View {
    // One binding for the combined address from Google
    @Binding var fullAddress: String
    
    // Separate bindings for the final splitted results
    @Binding var streetAddress: String
    @Binding var cityStateZip: String
    
    @Binding var isPickerPresented: Bool
    
    @State private var previousFullAddress: String = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text("What is your address?")
                .font(.title)
                .multilineTextAlignment(.center)
            
            Button(action: {
                isPickerPresented = true
            }) {
                if fullAddress.isEmpty {
                    Text("Tap to select your address")
                        .foregroundColor(.blue)
                        .underline()
                } else {
                    VStack {
                        Text("Selected Address:")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text(fullAddress)
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                }
            }
        }
        .onAppear {
            previousFullAddress = fullAddress
            // If we have a pre-filled address, parse it
            parseAndAssign(fullAddress)
        }
        .onChange(of: fullAddress) { newValue in
            previousFullAddress = newValue
            parseAndAssign(newValue)
        }
    }
    
    /// Splits the combined address into "street address" and "city/state/zip"
    private func parseAndAssign(_ combined: String) {
        // EXAMPLE SPLITTING STRATEGY:
        // 1) Attempt to split by newline,
        // 2) If not found, try last comma,
        // 3) else store everything in streetAddress.
        
        let lines = combined.components(separatedBy: "\n")
        if lines.count >= 2 {
            // First line is street, the rest joined is cityStateZip
            streetAddress = lines[0].trimmingCharacters(in: .whitespacesAndNewlines)
            cityStateZip = lines.dropFirst().joined(separator: ", ").trimmingCharacters(in: .whitespacesAndNewlines)
            return
        }
        
        // If no newline found, try to split by the last comma
        if let lastCommaRange = combined.range(of: ",", options: .backwards) {
            streetAddress = String(combined[..<lastCommaRange.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
            cityStateZip = String(combined[lastCommaRange.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
            return
        }
        
        // Fallback: everything is street address, cityStateZip empty
        streetAddress = combined
        cityStateZip = ""
    }
}

// MARK: - BasicInfoStepView
struct BasicInfoStepView: View {
    @Binding var email: String
    @Binding var firstName: String
    @Binding var lastName: String
    @Binding var dob: String
    @Binding var phone: String

    var body: some View {
        VStack(spacing: 30) {
            Text("Basic Info")
                .font(.title)
                .multilineTextAlignment(.center)
            
            Group {
                TextField("Email", text: $email)
                TextField("First Name", text: $firstName)
                TextField("Last Name", text: $lastName)
                TextField("DOB (MM/DD/YYYY)", text: $dob)
                TextField("Phone Number", text: $phone)
            }
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .padding(.horizontal, 100)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, 40)
    }
}

// MARK: - GenderRaceStep
struct GenderRaceStep: View {
    @Binding var selectedGender: String  // "Male" or "Female"
    
    // Gender booleans
    @Binding var isMale: Bool
    @Binding var isFemale: Bool

    // Race checkboxes
    @Binding var isWhite: Bool
    @Binding var isBlack: Bool
    @Binding var isAsian: Bool
    @Binding var isAmIndian: Bool

    var body: some View {
        VStack(spacing: 30) {
            Text("Gender & Race")
                .font(.title)
            
            Picker("Gender", selection: $selectedGender) {
                Text("Male").tag("Male")
                Text("Female").tag("Female")
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal, 50)
            .onChange(of: selectedGender) { newGender in
                updateGenderBooleans(newGender)
            }
            
            VStack(alignment: .leading, spacing: 10) {
                Toggle("White", isOn: $isWhite)
                Toggle("Black / African American", isOn: $isBlack)
                Toggle("Asian", isOn: $isAsian)
                Toggle("American Indian", isOn: $isAmIndian)
            }
            .padding(.horizontal, 100)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func updateGenderBooleans(_ gender: String) {
        isMale = (gender == "Male")
        isFemale = (gender == "Female")
    }
}




// MARK: - EthnicityStep
struct EthnicityStep: View {
    @Binding var isHispanic: Bool
    @Binding var isNonHispanic: Bool
    
    var body: some View {
        VStack(spacing: 30) {
            Text("Ethnicity")
                .font(.title)
            
            Toggle("Hispanic/Latino", isOn: $isHispanic)
            Toggle("Not Hispanic/Latino", isOn: $isNonHispanic)
        }
        .padding(.horizontal, 100)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - SignatureCanvasView
/// A SwiftUI wrapper around PencilKit's PKCanvasView.
struct SignatureCanvasView: UIViewRepresentable {
    @Binding var canvasView: PKCanvasView
    
    func makeUIView(context: Context) -> PKCanvasView {
        // Configure the PKCanvasView
        canvasView.drawingPolicy = .anyInput  // allows finger + Apple Pencil
        canvasView.tool = PKInkingTool(.pen, color: .black, width: 5)
        canvasView.backgroundColor = .white
        return canvasView
    }
    
    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        // Called when SwiftUI updates the view (e.g., state changes).
        // Usually no action needed unless we want to reconfigure the canvas.
    }
}

// MARK: - SignatureStep
struct SignatureStep: View {
    /// Holds the user's signature image (if we want to store it as an image).
    @Binding var signatureImage: UIImage?
    
    /// We could still keep a date if needed:
    @Binding var date: String
    
    /// The PencilKit canvas
    @State private var canvasView = PKCanvasView()
    
    var body: some View {
        VStack(spacing: 30) {
            Text("Signature")
                .font(.title)
            
            // The PencilKit wrapper
            SignatureCanvasView(canvasView: $canvasView)
                .frame(height: 300)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            
            // OPTIONAL: A date field
            TextField("Date (MM/DD/YYYY)", text: $date)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal, 100)
            
            // Buttons to handle the drawing
            HStack {
                Button("Clear") {
                    // Clears the canvas
                    canvasView.drawing = PKDrawing()
                }
                .padding(.horizontal)
                
                Button("Save Signature") {
                    // Extract an image from the drawing
                    let image = canvasView.drawing
                        .image(from: canvasView.bounds, scale: 1.0)
                    
                    // Store the image in your binding
                    signatureImage = image
                }
                .padding(.horizontal)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, 40)
    }
}


