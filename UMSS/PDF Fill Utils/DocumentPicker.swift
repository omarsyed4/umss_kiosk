//
//  DocumentPicker.swift
//  UMSS
//
//  Created by Omar Syed on 1/31/25.
//


import UIKit
import SwiftUI
import PDFKit

struct DocumentPicker: UIViewControllerRepresentable {
    let pdfDocument: PDFDocument

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        // Save PDF to a temporary URL first
        guard let pdfData = pdfDocument.dataRepresentation() else {
            fatalError("Failed to generate PDF data")
        }
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("ModifiedUMSS.pdf")
        do {
            try pdfData.write(to: tempURL)
        } catch {
            fatalError("Failed to write PDF data to temporary file: \(error.localizedDescription)")
        }
        
        // Initialize the document picker in export mode
        let picker = UIDocumentPickerViewController(forExporting: [tempURL])
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
}