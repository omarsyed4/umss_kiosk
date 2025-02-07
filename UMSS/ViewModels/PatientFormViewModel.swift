import SwiftUI
import PDFKit
import UIKit  // For UIImage

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
        
        // 1. Fill in the PDF form fields (text fields, checkboxes).
        fillPDF(pdfDocument: pdfDocument, with: patientForm)
        
        // 2. If we have a drawn signature image, place it as an annotation.
        addSignatureImage(pdfDocument: pdfDocument, signatureImage: patientForm.signatureImage)
        
        // 3. Save modified PDF to Documents directory (visible in Files if file sharing is enabled).
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
    
    /// -------------
    /// MARK: Fill AcroForm Fields (Text, Checkboxes)
    /// -------------
    private func fillPDF(pdfDocument: PDFDocument, with formData: PatientForm) {
        let pageCount = pdfDocument.pageCount
        if pageCount == 0 {
            print("[DEBUG] PDF has no pages")
            return
        }
        
        for pageIndex in 0..<pageCount {
            guard let page = pdfDocument.page(at: pageIndex) else { continue }
            for annotation in page.annotations {
                if let fieldName = annotation.fieldName {
                    switch fieldName {
                        // Text fields:
                    case "FullName":
                        print("[DEBUG] Found \"FullName\". Setting to: \(formData.fullName)")
                        annotation.contents = formData.fullName
                        
                    case "DOBField":
                        print("[DEBUG] Found \"DOBField\". Setting to: \(formData.dob)")
                        annotation.contents = formData.dob
                        
                    case "AddressField":
                        print("[DEBUG] Found \"AddressField\". Setting to: \(formData.address)")
                        annotation.contents = formData.address
                        print("Address: \(formData.address)")
                        print("City: \(formData.city)")
                        print("State: \(formData.state)")
                        print("Zip: \(formData.zip)")
                        print("City/State/Zip: \(formData.cityStateZip)")

                        
                    case "CityStateZipField":
                        print("[DEBUG] Found \"CityStateZipField\". Setting to: \(formData.cityStateZip)")
                        annotation.contents = formData.cityStateZip
                    
                    case "EmailField":
                        print("[DEBUG] Found \"EmailField\". Setting to: \(formData.email)")
                        annotation.contents = formData.email
                    
                    case "PhoneField":
                        print("[DEBUG] Found \"PhoneField\". Setting to: \(formData.phone)")
                        annotation.contents = formData.phone
                    
                    case "LastNameField":
                        print("[DEBUG] Found \"LastNameField\". Setting to: \(formData.lastName)")
                        annotation.contents = formData.lastName
                    
                    case "FirstNameField":
                        print("[DEBUG] Found \"FirstNameField\". Setting to: \(formData.firstName)")
                        annotation.contents = formData.firstName
                    
                    case "Date_6":
                        print("[DEBUG] Found \"Date\". Setting to: \(formData.date)")
                        annotation.contents = formData.date

                    case "Date_7":
                        print("[DEBUG] Found \"Date\". Setting to: \(formData.date)")
                        annotation.contents = formData.date

                    case "Date_8":
                        print("[DEBUG] Found \"Date\". Setting to: \(formData.date)")
                        annotation.contents = formData.date

                    case "Date_9":
                        print("[DEBUG] Found \"Date\". Setting to: \(formData.date)")
                        annotation.contents = formData.date

                        
                    case "PhoneField":
                        print("[DEBUG] Found \"PhoneField\". Setting to: \(formData.phone)")
                        annotation.contents = formData.phone
                        
                    case "Date":
                        print("[DEBUG] Found \"Date\". Setting to: \(formData.date)")
                        annotation.contents = formData.date
                        
                    // Gender Checkboxes
                    case "MaleCheck":
                        annotation.contents = (formData.isMale) ? "X" : ""
                        print("[DEBUG] \"MaleCheck\" => \(annotation.contents ?? "Off")")

                    case "FemaleCheck":
                        annotation.contents = (formData.isFemale) ? "X" : ""
                        print("[DEBUG] \"FemaleCheck\" => \(annotation.contents ?? "Off")")

                    // Checkboxes:
                    case "WhiteCheck":
                        annotation.contents = (formData.isWhite) ? "X" : ""
                        print("[DEBUG] \"WhiteCheck\" => \(annotation.contents ?? "Off")")

                    case "BlackCheck":
                        annotation.contents = (formData.isBlack) ? "X" : ""
                        print("[DEBUG] \"BlackCheck\" => \(annotation.contents ?? "Off")")

                    case "AsianCheck":
                        annotation.contents = (formData.isAsian) ? "X" : ""
                        print("[DEBUG] \"AsianCheck\" => \(annotation.contents ?? "Off")")

                    case "AmIndianCheck":
                        annotation.contents = (formData.isAmIndian) ? "X" : ""
                        print("[DEBUG] \"AmIndianCheck\" => \(annotation.contents ?? "Off")")

                    case "HispanicCheck":
                        annotation.contents = (formData.isHispanic) ? "X" : ""
                        print("[DEBUG] \"HispanicCheck\" => \(annotation.contents ?? "Off")")
                        
                    case "NonHispanicCheck":
                        annotation.contents = (formData.isNonHispanic) ? "X" : ""
                        print("[DEBUG] \"HispanicCheck\" => \(annotation.contents ?? "Off")")

                    default:
                        print("[WARNING] No matching case for field: \(fieldName)")
                    }
                    
                    // Force PDFKit to refresh the field display
                    annotation.widgetStringValue = annotation.contents ?? ""
                    annotation.setValue((annotation.contents ?? "") as NSString, forAnnotationKey: .widgetValue)
                }
            }
        }
    }
    
    
    /// -------------
    /// MARK: Add Signature Image as a Stamp Annotation
    /// -------------
    private func addSignatureImage(pdfDocument: PDFDocument, signatureImage: UIImage?) {
        guard let sigImage = signatureImage else {
            print("[DEBUG] No signature image found.")
            return
        }

        guard let firstPage = pdfDocument.page(at: 1) else {
            print("[DEBUG] Could not get first page for signature annotation.")
            return
        }

        let annotationBounds = CGRect(x: 105, y: 500, width: 100, height: 25)

        // Create our custom stamp annotation with the image.
        let stampAnnotation = StampAnnotation(bounds: annotationBounds, image: sigImage)

        // Add the annotation to the page.
        firstPage.addAnnotation(stampAnnotation)
        print("[DEBUG] Placed signature image annotation on page 0 at \(annotationBounds).")
    }
}

/// A custom PDFAnnotation subclass that draws a UIImage into the annotation's bounds.
class StampAnnotation: PDFAnnotation {
    let stampImage: UIImage
    
    init(bounds: CGRect, image: UIImage) {
        self.stampImage = image
        super.init(bounds: bounds, forType: .stamp, withProperties: nil)
        // Remove border completely
        self.border = PDFBorder()
        self.border?.lineWidth = 0
        self.color = .clear
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(with box: PDFDisplayBox, in context: CGContext) {
        // Remove super.draw() to avoid default border rendering
        guard let cgImage = stampImage.cgImage else { return }
        
        context.saveGState()
        context.translateBy(x: bounds.minX, y: bounds.minY)
        
        let drawingRect = CGRect(origin: .zero, size: bounds.size)
        context.draw(cgImage, in: drawingRect)
        
        context.restoreGState()
    }
}
