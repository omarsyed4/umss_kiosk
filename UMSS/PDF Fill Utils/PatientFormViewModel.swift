import SwiftUI
import PDFKit
import UIKit

class PatientModelViewModel: ObservableObject {
    @Published var patientModel = PatientModel()

    func generateFilledPDF() -> PDFDocument? {
        guard let formURL = Bundle.main.url(forResource: "UMSS Document", withExtension: "pdf") else {
            return nil
        }
        
        guard let pdfDocument = PDFDocument(url: formURL) else {
            print("[ERROR] Could not create PDFDocument from URL.")
            return nil
        }
        print("[DEBUG] Successfully loaded PDF. Page count: \(pdfDocument.pageCount)")
        
        // Use the new PDF functions to fill and add the signature
        PDFGenerator.fillPDF(pdfDocument: pdfDocument, with: patientModel)
        PDFGenerator.addSignatureImage(pdfDocument: pdfDocument, signatureImage: patientModel.signatureImage)
        
        if let pdfData = pdfDocument.dataRepresentation() {
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let fileURL = documentsURL.appendingPathComponent("ModifiedUMSS.pdf")
            do {
                try pdfData.write(to: fileURL)
                print("[DEBUG] Saved modified PDF at: \(fileURL.path)")
                
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
}
