//
//  PDFPreviewView.swift
//  UMSS
//
//  Created by Omar Syed on 1/29/25.
//

import SwiftUI
import PDFKit

struct PDFPreviewView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var showUploadAlert = false
    @State private var showPrintAlert = false
    @State private var uploadStatus: UploadStatus?
    @State private var isUploading = false
    
    let pdfDocument: PDFDocument
    var onUpload: (() -> Result<Void, Error>)? = nil
    var onPrint: (() -> Void)? = nil

    // Make UploadStatus conform to Identifiable
    enum UploadStatus: Identifiable {
        case success(message: String)
        case failure(error: String)

        var id: UUID { UUID() } // Unique ID for SwiftUI
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            // Main content
            VStack(spacing: 0) {
                PDFContentSection()
                
                ActionButtonsSection()
            }
            
            // Loading overlay
            if isUploading {
                LoadingOverlay()
            }
        }
        .alert(item: $uploadStatus) { status in
            switch status {
            case .success(let message):
                return Alert(title: Text("Success"), message: Text(message), dismissButton: .default(Text("OK")))
            case .failure(let error):
                return Alert(title: Text("Error"), message: Text(error), dismissButton: .default(Text("OK")))
            }
        }
        .confirmationDialog("Print Document", isPresented: $showPrintAlert) {
            Button("Print", role: .none) {
                printPDF()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to print this document?")
        }
        .navigationBarHidden(true)
        .statusBar(hidden: true)
    }

    // MARK: - Subviews
    
    private func PDFContentSection() -> some View {
        VStack(spacing: 0) {
            HStack {
                Text("Document Preview")
                    .font(.title3.weight(.semibold))
                    .foregroundColor(.primary)
                    .font(.system(size: 40))
                Spacer()
                CloseButton()
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial)
            
            PDFKitView(document: pdfDocument)
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.1), radius: 12, x: 0, y: 4)
                .padding(.horizontal)
                .padding(.vertical, 8)
                .frame(maxHeight: .infinity)
        }
    }
    
    private func ActionButtonsSection() -> some View {
        HStack(spacing: 16) {
            ActionButton(
                title: "Print",
                icon: "printer",
                color: UMSSBrand.navy,
                action: { showPrintAlert = true }
            )
            
            ActionButton(
                title: "Upload",
                icon: "cloud",
                color: UMSSBrand.navy,
                action: handleUpload
            )
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
    }
    
    private func CloseButton() -> some View {
        Button(action: { presentationMode.wrappedValue.dismiss() }) {
            Image(systemName: "xmark.circle.fill")
                .symbolRenderingMode(.hierarchical)
                .font(.system(size: 24))
                .foregroundColor(.secondary)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
    }
    
    private func ActionButton(title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24) // Adjust size here
                Text(title)
            }
                .font(.subheadline.weight(.bold))
                .font(.system(size: 24))
                .frame(maxWidth: .infinity)
                .padding(12)
                .foregroundColor(.white)
                .background(UMSSBrand.navy)
                .cornerRadius(10)
                .shadow(color: color.opacity(0.2), radius: 4, y: 2)
        }
    }
    
    private func LoadingOverlay() -> some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(1.5)
                .padding(24)
                .background(.ultraThinMaterial)
                .cornerRadius(16)
        }
    }
    
    // MARK: - Handlers
    
    private func handleUpload() {
        isUploading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            defer { isUploading = false }
            guard let result = onUpload?() else {
                uploadStatus = .failure(error: "Upload action not configured")
                return
            }
            
            switch result {
            case .success:
                uploadStatus = .success(message: "Your document has been securely uploaded to Google Drive")
            case .failure(let error):
                uploadStatus = .failure(error: error.localizedDescription)
            }
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


