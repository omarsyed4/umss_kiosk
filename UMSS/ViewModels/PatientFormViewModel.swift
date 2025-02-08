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
                        annotation.contents = formData.fullName
                        
                    case "DOBField":
                        annotation.contents = formData.dob
                        
                    case "AddressField":
                        annotation.contents = formData.address

                        
                    case "CityStateZipField":
                        annotation.contents = formData.cityStateZip

                    case "ZipField":
                        annotation.contents = formData.zip

                    case "EmailField":
                        annotation.contents = formData.email
                    
                    case "PhoneField":
                        annotation.contents = formData.phone
                    
                    case "LastNameField":
                        annotation.contents = formData.lastName
                    
                    case "FirstNameField":
                        annotation.contents = formData.firstName

                    case "GenderField":
                        annotation.contents = formData.genderString

                    case "RaceField":
                        annotation.contents = formData.raceString
                    
                    case "EthnicityField":
                        annotation.contents = formData.ethnicityString

                    case "Date_6":
                        annotation.contents = formData.date

                    case "Date_7":
                        annotation.contents = formData.date

                    case "Date_8":
                        annotation.contents = formData.date

                    case "Date_9":
                        annotation.contents = formData.date

                        
                    case "Address_2":
                        annotation.contents = formData.address
                    
                    case "CityStateField":
                        annotation.contents = formData.cityState
                    
                    
                    case "Date":
                        annotation.contents = formData.date
                        
                    // Gender Checkboxes
                    case "MaleCheck":
                        annotation.contents = (formData.isMale) ? "X" : ""

                    case "FemaleCheck":
                        annotation.contents = (formData.isFemale) ? "X" : ""

                    // Checkboxes:
                    case "WhiteCheck":
                        annotation.contents = (formData.isWhite) ? "X" : ""

                    case "BlackCheck":
                        annotation.contents = (formData.isBlack) ? "X" : ""

                    case "AsianCheck":
                        annotation.contents = (formData.isAsian) ? "X" : ""

                    case "AmIndianCheck":
                        annotation.contents = (formData.isAmIndian) ? "X" : ""

                    case "HispanicCheck":
                        annotation.contents = (formData.isHispanic) ? "X" : ""
                        
                    case "NonHispanicCheck":
                        annotation.contents = (formData.isNonHispanic) ? "X" : ""
                        
                    case "InsuredNo":
                        annotation.contents = (formData.insuredNo) ? "X" : ""

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
        
        // Define signature bounds for each page (pages are zero-indexed).
        // Adjust the CGRect values to position the signatures as desired.
        let signatureBoundsPerPage: [Int: [CGRect]] = [
            1: [CGRect(x: 105, y: 500, width: 100, height: 25)],
            2: [CGRect(x: 80, y: 70, width: 100, height: 25)],
            3: [
                CGRect(x: 220, y: 350, width: 100, height: 25),
                CGRect(x: 105, y: 210, width: 100, height: 25),
                CGRect(x: 105, y: 135, width: 100, height: 25),
                CGRect(x: 105, y: 87, width: 100, height: 25),
                CGRect(x: 105, y: 45, width: 100, height: 25),
            ],
        ]
        
        // Loop over each page index with defined signature bounds.
        for (pageIndex, boundsArray) in signatureBoundsPerPage {
            guard let page = pdfDocument.page(at: pageIndex) else {
                print("[DEBUG] Could not get page at index \(pageIndex).")
                continue
            }
            
            // Add all signature annotations for this page.
            for bounds in boundsArray {
                let stampAnnotation = StampAnnotation(bounds: bounds, image: sigImage)
                page.addAnnotation(stampAnnotation)
                print("[DEBUG] Placed signature image annotation on page \(pageIndex + 1) at \(bounds).")
            }
        }
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
