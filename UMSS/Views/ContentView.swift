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
    private var totalSteps: Int { 5 }

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
                                city: $viewModel.patientForm.city,
                                state: $viewModel.patientForm.state,
                                zip: $viewModel.patientForm.zip,
                                cityStateZip: $viewModel.patientForm.cityStateZip,
                                isPickerPresented: $isAddressPickerPresented
                            )
                                                        

                        // Step 3 - Gender & Race
                        } else if currentStep == 3 {
                            DemographicsStep(
                                selectedGender: $viewModel.patientForm.selectedGender,
                                selectedRace: $viewModel.patientForm.selectedRace,
                                selectedMaritalStatus: $viewModel.patientForm.selectedMaritalStatus,
                                selectedEthnicity: $viewModel.patientForm.selectedEthnicity
                            )

                        // Step 4 - Signature & Date
                        } else if currentStep == 4 {
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
    @Binding var fullAddress: String
    
    // Split into individual bindings
    @Binding var streetAddress: String
    @Binding var city: String
    @Binding var state: String
    @Binding var zip: String
    
    // Combined "City, State Zip"
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
                print("Picker presented")
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
            print("onAppear called")
        }
        .onChange(of: fullAddress) { newValue in
            print("onChange called with new value: \(newValue)")
            
        }
    }
}


// MARK: - BasicInfoStepView
struct BasicInfoStepView: View {
    @Binding var email: String
    @Binding var firstName: String
    @Binding var lastName: String
    @Binding var dob: String
    @Binding var phone: String

    @State private var selectedDate: Date = Date()
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Basic Information")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .padding(.bottom, 10)

            VStack(spacing: 15) {
                CustomTextField(icon: "envelope", placeholder: "Email", text: $email, keyboardType: .emailAddress)
                CustomTextField(icon: "person", placeholder: "First Name", text: $firstName, keyboardType: .default)
                CustomTextField(icon: "person", placeholder: "Last Name", text: $lastName, keyboardType: .default)
                
                // Date Picker for DOB
                VStack(alignment: .leading, spacing: 5) {
                    Text("Date of Birth")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    DatePicker("Select Date", selection: $selectedDate, displayedComponents: .date)
                        .datePickerStyle(CompactDatePickerStyle())
                        .labelsHidden()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .onChange(of: selectedDate) { newValue in
                            let formatter = DateFormatter()
                            formatter.dateFormat = "MM/dd/yyyy"
                            dob = formatter.string(from: newValue)
                        }
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemGray6)))
                
                CustomTextField(icon: "phone", placeholder: "Phone Number", text: $phone, keyboardType: .phonePad)
            }
            .padding(.horizontal, 25)
            
            Spacer()
        }
        .padding(.vertical, 40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground).edgesIgnoringSafeArea(.all))
    }
}

// MARK: - Custom TextField with Icons
struct CustomTextField: View {
    var icon: String
    var placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.gray)
                .frame(width: 20)
            
            TextField(placeholder, text: $text)
                .keyboardType(keyboardType)
                .padding(.vertical, 10)
        }
        .padding(.horizontal, 15)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemGray6)))
    }
}

// MARK: - DemographicsStep
struct DemographicsStep: View {
    @Binding var selectedGender: String
    @Binding var selectedRace: String
    @Binding var selectedMaritalStatus: String
    @Binding var selectedEthnicity: String
    
    private let genderOptions = ["Male", "Female"]
    private let raceOptions = ["White", "Black / African American", "Asian", "American Indian"]
    private let maritalStatusOptions = ["Single", "Married", "Divorced", "Widowed"]
    private let ethnicityOptions = ["Hispanic/Latino", "Not Hispanic/Latino"]
    
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
                            }
                        }
                    }
                    .padding(.vertical, 8)
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


