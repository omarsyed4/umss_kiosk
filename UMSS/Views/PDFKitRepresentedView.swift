//
//  PDFKitRepresentedView.swift
//  UMSS
//
//  Created by Omar Syed on 1/29/25.
//


import SwiftUI
import PDFKit

/// A UIViewRepresentable that displays a PDFDocument in SwiftUI
struct PDFKitRepresentedView: UIViewRepresentable {
    let pdfDocument: PDFDocument
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = pdfDocument
        pdfView.autoScales = true
        return pdfView
    }
    
    func updateUIView(_ uiView: PDFView, context: Context) {
        // If needed, update the PDF document
        uiView.document = pdfDocument
    }
}
