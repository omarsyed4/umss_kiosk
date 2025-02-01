//
//  PatientForm.swift
//  UMSS
//
//  Created by Omar Syed on 1/29/25.
//

import SwiftUI
import PDFKit

/// ViewModel that handles generating and filling the PDF
class PatientFormViewModel: ObservableObject {
    @Published var patientForm = PatientForm()
    
    /// Loads the PDF from the bundle, fills in the form fields, and returns the updated PDFDocument
    func generateFilledPDF() -> PDFDocument? {
        print("[DEBUG] Attempting to load PDF from bundle...")
        guard let formURL = Bundle.main.url(forResource: "UMSS Document", withExtension: "pdf") else {
            print("[ERROR] Could not find UMSS Document.pdf in bundle.")
            return nil
        }
        print("[DEBUG] Found PDF file at: \(formURL.path)")

        guard let pdfDocument = PDFDocument(url: formURL) else {
            print("[ERROR] Could not create PDFDocument from URL.")
            return nil
        }
        print("[DEBUG] Successfully loaded PDF. Page count: \(pdfDocument.pageCount)")

        // Fill in the PDF form fields
        fillPDF(pdfDocument: pdfDocument, with: patientForm)

        // 🔥 Save modified PDF to Documents directory (visible in Files if file sharing is enabled)
        if let pdfData = pdfDocument.dataRepresentation() {
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let fileURL = documentsURL.appendingPathComponent("ModifiedUMSS.pdf")
            do {
                try pdfData.write(to: fileURL)
                print("[DEBUG] Saved modified PDF at: \(fileURL.path)")
                
                // Attempt to reload the saved PDF to verify integrity
                if let reloadedPDF = PDFDocument(url: fileURL) {
                    print("[DEBUG] Reloaded saved PDF successfully! Page count: \(reloadedPDF.pageCount)")
                    return reloadedPDF
                } else {
                    print("[ERROR] Reloaded PDF is nil!")
                }
            } catch {
                print("[ERROR] Failed to save modified PDF: \(error.localizedDescription)")
            }
        } else {
            print("[ERROR] pdfDocument.dataRepresentation() is nil! The PDF may be corrupted.")
        }
        return nil
    }

    /// Uses PDFKit to fill out the form fields by name
    private func fillPDF(pdfDocument: PDFDocument, with formData: PatientForm) {
        let pageCount = pdfDocument.pageCount
        
        if pageCount == 0 {
            print("[DEBUG] PDF has no pages")
            return
        }
        
        for pageIndex in 0..<pageCount {
            guard let page = pdfDocument.page(at: pageIndex) else { continue }
            
            let annotations = page.annotations
            for annotation in annotations {
                if let fieldName = annotation.fieldName {
                    print("[DEBUG] Found annotation: \(fieldName), widget type: \(annotation.widgetFieldType.rawValue)")
                } else {
                    print("[DEBUG] Found annotation with NO fieldName")
                }
                
                if annotation.widgetFieldType == .text {
                    print("[DEBUG] Processing text field: \(annotation.fieldName ?? "Unknown")")

                    switch annotation.fieldName {
                    case "EmailField":
                        annotation.contents = formData.email
                        print("[DEBUG] Setting EmailField to: \(formData.email)")
                    case "FirstNameField":
                        annotation.contents = formData.firstName
                        print("[DEBUG] Setting FirstNameField to: \(formData.firstName)")
                    case "LastNameField":
                        annotation.contents = formData.lastName
                        print("[DEBUG] Setting LastNameField to: \(formData.lastName)")
                    case "PhoneField":
                        annotation.contents = formData.phoneNumber
                        print("[DEBUG] Setting PhoneField to: \(formData.phoneNumber)")
                    case "DOBField":
                        annotation.contents = formData.dob
                        print("[DEBUG] Setting DOBField to: \(formData.dob)")
                    case "AddressField":
                        annotation.contents = formData.address
                        print("[DEBUG] Setting AddressField to: \(formData.address)")
                    case "RaceField":
                        annotation.contents = formData.race
                        print("[DEBUG] Setting RaceField to: \(formData.race)")
                    case "EthnicityField":
                        annotation.contents = formData.ethnicity
                        print("[DEBUG] Setting EthnicityField to: \(formData.ethnicity)")
                    case "MonthlyIncomeField":
                        annotation.contents = formData.monthlyIncome
                        print("[DEBUG] Setting MonthlyIncomeField to: \(formData.monthlyIncome)")
                    default:
                        print("[WARNING] No matching case for field: \(annotation.fieldName ?? "Unknown")")
                        break
                    }
                    
                    // 🔥 Force UI update for form fields
                    annotation.widgetStringValue = annotation.contents ?? ""  // ✅ Unwrap safely
                    annotation.setValue((annotation.contents ?? "") as NSString, forAnnotationKey: .widgetValue)  // ✅ Use NSString (required for PDFKit)
                }
            }
        }
    }
}
