//
//  DemographicsStep.swift
//  UMSS
//
//  Created by GitHub Copilot
//

import SwiftUI

struct DemographicsStep: View {
    // Existing demographic bindings
    @Binding var selectedGender: String
    @Binding var selectedRace: String
    @Binding var selectedMaritalStatus: String
    @Binding var selectedEthnicity: String
    @Binding var selectedIncome: String  // NEW: Binding for income
    
    // Gender-related bindings
    @Binding var isMale: Bool
    @Binding var isFemale: Bool
    
    // Race-related bindings
    @Binding var isWhite: Bool
    @Binding var isBlack: Bool
    @Binding var isAsian: Bool
    @Binding var isAmIndian: Bool
    
    // Ethnicity-related bindings
    @Binding var isHispanic: Bool
    @Binding var isNonHispanic: Bool
    
    // Marital status-related bindings
    @Binding var isSingle: Bool
    @Binding var isMarried: Bool
    @Binding var isDivorced: Bool
    @Binding var isWidowed: Bool

    @Binding var selectedFamilySize: String
    @Binding var selectedIncomeThreshold: String

    // Address-related bindings
    @Binding var fullAddress: String
    @Binding var streetAddress: String
    @Binding var city: String
    @Binding var state: String
    @Binding var zip: String
    @Binding var cityStateZip: String
    @Binding var isPickerPresented: Bool

    private let genderOptions = ["Male", "Female"]
    private let raceOptions = ["White", "Black / African American", "Asian", "American Indian"]
    private let maritalStatusOptions = ["Single", "Married", "Divorced", "Widowed"]
    private let ethnicityOptions = ["Hispanic/Latino", "Not Hispanic/Latino"]
    private let incomeOptions = [
        "1 Person - $2430 or Less",
        "2 Persons - $3287 or Less",
        "3 Persons - $4143 or Less",
        "4 Persons - $5000 or Less",
        "Zero - No Income"
    ]
    
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
                                if selectedGender == "Male" {
                                    isMale = true
                                    isFemale = false
                                } else {
                                    isMale = false
                                    isFemale = true
                                }
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
                                if option == "White" {
                                    isWhite = true
                                    isBlack = false
                                    isAsian = false
                                    isAmIndian = false
                                } else if option == "Black / African American" {
                                    isWhite = false
                                    isBlack = true
                                    isAsian = false
                                    isAmIndian = false
                                } else if option == "Asian" {
                                    isWhite = false
                                    isBlack = false
                                    isAsian = true
                                    isAmIndian = false
                                } else if option == "American Indian" {
                                    isWhite = false
                                    isBlack = false
                                    isAsian = false
                                    isAmIndian = true
                                }
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
                                    if option == "Single" {
                                        isSingle = true
                                        isMarried = false
                                        isDivorced = false
                                        isWidowed = false
                                    } else if option == "Married" {
                                        isSingle = false
                                        isMarried = true
                                        isDivorced = false
                                        isWidowed = false
                                    } else if option == "Divorced" {
                                        isSingle = false
                                        isMarried = false
                                        isDivorced = true
                                        isWidowed = false
                                    } else if option == "Widowed" {
                                        isSingle = false
                                        isMarried = false
                                        isDivorced = false
                                        isWidowed = true
                                    }
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
                                if option == "Hispanic/Latino" {
                                    isHispanic = true
                                    isNonHispanic = false
                                } else {
                                    isHispanic = false
                                    isNonHispanic = true
                                }
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                // Income Section
                SectionCard(title: "Income") {
                    VStack(spacing: 12) {
                        ForEach(incomeOptions, id: \.self) { option in
                            ChoiceRow(
                                title: option,
                                isSelected: selectedIncome == option
                            ) {
                                selectedIncome = option
                                // Split the option String into two parts separated by " - "
                                let parts = option.components(separatedBy: " - ")
                                if parts.count == 2 {
                                    selectedFamilySize = parts[0].trimmingCharacters(in: .whitespaces)
                                    selectedIncomeThreshold = parts[1].trimmingCharacters(in: .whitespaces)
                                }
                            }

                        }
                    }
                    .padding(.vertical, 8)
                }
                
                // Address Section (integrated widget)
                SectionCard(title: "Address") {
                    Button(action: {
                        isPickerPresented = true
                    }) {
                        HStack(spacing: 15) {
                            Image(systemName: "mappin.and.ellipse")
                                .foregroundColor(.blue)
                                .font(.title2)
                            
                            VStack(alignment: .leading, spacing: 5) {
                                if fullAddress.isEmpty {
                                    Text("Tap to select your address")
                                        .font(.body)
                                        .foregroundColor(.blue)
                                        .underline()
                                } else {
                                    Text("Selected Address:")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    Text(fullAddress)
                                        .font(.body)
                                        .foregroundColor(.primary)
                                        .multilineTextAlignment(.leading)
                                }
                            }
                            
                            Spacer()
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemGray6))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.blue.opacity(0.7), lineWidth: 1)
                        )
                        .animation(.easeInOut, value: fullAddress)
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }
}
