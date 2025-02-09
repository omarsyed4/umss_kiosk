//
//  PDFPreviewView.swift
//  UMSS
//
//  Created by Omar Syed on 1/29/25.
//

import SwiftUI
import PDFKit

struct PDFPreviewView: View {
    let pdfDocument: PDFDocument
    var onUpload: (() -> Void)? = nil
    
    var body: some View {
        VStack {
            PDFKitView(document: pdfDocument)
                .edgesIgnoringSafeArea(.all)
            
            HStack {
                Button("Print") {
                    // Implement print functionality if desired.
                }
                Spacer()
                Button("Upload") {
                    onUpload?()
                }
            }
            .padding()
        }
    }


        
private func printPDF() {
    guard let pdfData = pdfDocument.dataRepresentation() else {
        print("[ERROR] Could not get PDF data for printing.")
        return
    }
    
    let printController = UIPrintInteractionController.shared
    let printInfo = UIPrintInfo(dictionary: nil)
    printInfo.outputType = .general
    printInfo.jobName = "UMSS Document"
    printController.printInfo = printInfo
    printController.printingItem = pdfData
    
    // Present the print interaction controller.
    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
       let rootVC = windowScene.windows.first?.rootViewController {
        printController.present(from: rootVC.view.frame, in: rootVC.view, animated: true, completionHandler: nil)
    } else {
        printController.present(animated: true, completionHandler: nil)
    }
}
}


