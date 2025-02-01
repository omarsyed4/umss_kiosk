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
    
    private let incomeOptions = [
        "1 Person - $2430 or Less",
        "2 Persons - $3287 or Less",
        "3 Persons - $4143 or Less",
        "4 Persons - $5000 or Less",
        "Zero - No Income",
        "Other"
    ]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Patient Information")) {
                    TextField("Email", text: $viewModel.patientForm.email)
                    TextField("First Name", text: $viewModel.patientForm.firstName)
                    TextField("Last Name", text: $viewModel.patientForm.lastName)
                    TextField("Phone Number", text: $viewModel.patientForm.phoneNumber)
                    TextField("DOB", text: $viewModel.patientForm.dob)
                    TextField("Address", text: $viewModel.patientForm.address)
                    TextField("Race", text: $viewModel.patientForm.race)
                    TextField("Ethnicity", text: $viewModel.patientForm.ethnicity)
                    
                    Picker("Monthly Income", selection: $viewModel.patientForm.monthlyIncome) {
                        ForEach(incomeOptions, id: \.self) { option in
                            Text(option).tag(option)
                        }
                    }
                }
                
                // Button to fill and preview the PDF
                Button("Preview PDF") {
                    pdfDocument = viewModel.generateFilledPDF()

                    if pdfDocument == nil {
                        print("[ERROR] pdfDocument is nil after generation!")
                    } else {
                        print("[DEBUG] pdfDocument successfully generated. Showing preview...")
                    }

                    showPDFPreview = true
                }
                .font(.headline)
            }
            .navigationTitle("Intake Form")
            
            // Present the PDF in a sheet
            .sheet(isPresented: $showPDFPreview) {
                if let modifiedPDF = viewModel.generateFilledPDF() {
                    // If you have a valid modified PDF, preview it
                    PDFPreviewView(pdfDocument: modifiedPDF)
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle()) // For a single-column layout on iPad
    }
}
