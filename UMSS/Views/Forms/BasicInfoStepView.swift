//
//  BasicInfoStepView.swift
//  UMSS
//
//  Created by GitHub Copilot
//

import SwiftUI

struct BasicInfoStepView: View {
    // Basic Information Bindings
    @Binding var email: String
    @Binding var firstName: String
    @Binding var lastName: String
    @Binding var dob: String
    @Binding var age: String
    @Binding var phone: String
    @Binding var reasonForVisit: String
    @Binding var isExistingPatient: Bool
    
    // Use the patient's date of birth or default to today
    @State private var selectedDate: Date
    
    // Initialize with a date parameter
    init(email: Binding<String>, firstName: Binding<String>, lastName: Binding<String>, 
         dob: Binding<String>, age: Binding<String>, phone: Binding<String>, 
         reasonForVisit: Binding<String>, isExistingPatient: Binding<Bool>, 
         initialDate: Date = Date()) {
        self._email = email
        self._firstName = firstName
        self._lastName = lastName
        self._dob = dob
        self._age = age
        self._phone = phone
        self._reasonForVisit = reasonForVisit
        self._isExistingPatient = isExistingPatient
        self._selectedDate = State(initialValue: initialDate)
    }
    
        
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
                
                // MARK: - Basic Information Section (Names, DOB, Age)
                SectionCard(title: "Basic Information") {
                    // A single HStack containing First/Last Name and DOB side by side
                    HStack(spacing: 20) {

                            TextField("First Name", text: $firstName)
                                .padding(12)
                                .background(Color.white)
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                                )

                            TextField("Last Name", text: $lastName)
                                .padding(12)
                                .background(Color.white)
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                                )
                        

                        // DOB Field
                        VStack(spacing: 10) {
                            HStack(spacing: 10) {
                                Text("DOB")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                DatePicker("", selection: $selectedDate, displayedComponents: .date)
                                    .datePickerStyle(CompactDatePickerStyle())
                                    .labelsHidden()
                                    .onChange(of: selectedDate) { newValue in
                                        // Update dob as formatted string
                                        let formatter = DateFormatter()
                                        formatter.dateFormat = "MM/dd/yyyy"
                                        dob = formatter.string(from: newValue)
                                        
                                        // Calculate age from the selected date
                                        let now = Date()
                                        let ageComponents = Calendar.current.dateComponents([.year], from: newValue, to: now)
                                        age = "\(ageComponents.year ?? 0)"
                                    }
                            }
                            .padding(12)
                            .background(Color.white)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                            )

                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                
                // MARK: - New Contact Info Section (Email and Phone in One Row)
                SectionCard(title: "Contact Info") {
                    VStack(spacing: 20) {
                        // Email Field
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Email")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
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
                                            if (!email.contains("@")) {
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
                                            if (!email.contains("@")) {
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
                                            if (!email.contains("@")) {
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
                                            if (!email.contains("@")) {
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
                                            if (!email.contains("@")) {
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

                        }
                        VStack {
                            // Phone Field
                            VStack(alignment: .leading, spacing: 5) {
                                Text("Phone")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                TextField("Phone", text: $phone)
                                    .keyboardType(.numberPad)
                                    .padding(12)
                                    .background(Color.white)
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                                    )
                                    .onChange(of: phone) { newValue in
                                        // Filter out non-digit characters
                                        let digits = newValue.filter { $0.isNumber }
                                        // Format the number
                                        phone = formatPhoneNumber(digits)
                                    }
                            }
                        }
                    }
                }
                
                // MARK: - Reason for Visit Section
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
                
                // MARK: - New or Existing Patient Section
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
            }
            .padding(.vertical, 30)
            .padding(.horizontal)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }
}
