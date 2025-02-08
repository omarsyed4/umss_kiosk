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
                            print("FullName set to: \(formData.fullName)")

                        case "DOBField":
                            annotation.contents = formData.dob
                            print("DOBField set to: \(formData.dob)")

                        case "AddressField":
                            annotation.contents = formData.address
                            print("AddressField set to: \(formData.address)")

                        case "CityStateZipField":
                            annotation.contents = formData.cityStateZip
                            print("CityStateZipField set to: \(formData.cityStateZip)")

                        case "ZipField":
                            annotation.contents = formData.zip
                            print("ZipField set to: \(formData.zip)")

                        case "EmailField":
                            annotation.contents = formData.email
                            print("EmailField set to: \(formData.email)")

                        case "PhoneField":
                            annotation.contents = formData.phone
                            print("PhoneField set to: \(formData.phone)")

                        case "LastNameField":
                            annotation.contents = formData.lastName
                            print("LastNameField set to: \(formData.lastName)")

                        case "FirstNameField":
                            annotation.contents = formData.firstName
                            print("FirstNameField set to: \(formData.firstName)")

                        case "GenderField":
                            annotation.contents = formData.genderString
                            print("GenderField set to: \(formData.genderString)")
                        
                        case "MaritalStatusField":
                            annotation.contents = formData.selectedMaritalStatus
                            print("MaritalStatusField set to: \(formData.selectedMaritalStatus)")

                        case "RaceField":
                            annotation.contents = formData.raceString
                            print("RaceField set to: \(formData.raceString)")

                        case "EthnicityField":
                            annotation.contents = formData.ethnicityString
                            print("EthnicityField set to: \(formData.ethnicityString)")

                        case "Date_6":
                            annotation.contents = formData.date
                            print("Date_6 set to: \(formData.date)")

                        case "Date_7":
                            annotation.contents = formData.date
                            print("Date_7 set to: \(formData.date)")

                        case "Date_8":
                            annotation.contents = formData.date
                            print("Date_8 set to: \(formData.date)")

                        case "Date_9":
                            annotation.contents = formData.date
                            print("Date_9 set to: \(formData.date)")

                        case "Address_2":
                            annotation.contents = formData.address
                            print("Address_2 set to: \(formData.address)")

                        case "FullAddress":
                            annotation.contents = formData.rawAddress
                            print("Address_2 set to: \(formData.rawAddress)")

                        case "CityStateField":
                            annotation.contents = formData.cityState
                            print("CityStateField set to: \(formData.cityState)")

                        case "Date":
                            annotation.contents = formData.date
                            print("Date field set to: \(formData.date)")

                        // Gender Checkboxes
                        case "MaleCheck":
                            annotation.contents = (formData.isMale) ? "X" : ""
                            print("MaleCheck set to: \(String(describing: annotation.contents))")
                            print("Patient form isMale: \(formData.isMale)")

                        case "FemaleCheck":
                            annotation.contents = (formData.isFemale) ? "X" : ""
                            print("FemaleCheck set to: \(String(describing: annotation.contents))")
                            print("Patient form isFemale: \(formData.isFemale)")
                        
                        case "NewPatientNo":
                            annotation.contents = (formData.isExistingPatient) ? "X" : ""
                            print("ExistingPatientCheck set to: \(String(describing: annotation.contents))")

                        case "NewPatientYes":
                            annotation.contents = (formData.isExistingPatient) ? "" : "X"
                            print("NewPatientYes set to: \(String(describing: annotation.contents))")

                        // Race Checkboxes
                        case "WhiteCheck":
                            annotation.contents = (formData.isWhite) ? "X" : ""
                            print("WhiteCheck set to: \(String(describing: annotation.contents))")

                        case "BlackCheck":
                            annotation.contents = (formData.isBlack) ? "X" : ""
                            print("BlackCheck set to: \(String(describing: annotation.contents))")

                        case "AsianCheck":
                            annotation.contents = (formData.isAsian) ? "X" : ""
                            print("AsianCheck set to: \(String(describing: annotation.contents))")

                        case "AmIndianCheck":
                            annotation.contents = (formData.isAmIndian) ? "X" : ""
                            print("AmIndianCheck set to: \(String(describing: annotation.contents))")

                        // Ethnicity Checkboxes
                        case "HispanicCheck":
                            annotation.contents = (formData.isHispanic) ? "X" : ""
                            print("HispanicCheck set to: \(String(describing: annotation.contents))")

                        case "NonHispanicCheck":
                            annotation.contents = (formData.isNonHispanic) ? "X" : ""
                            print("NonHispanicCheck set to: \(String(describing: annotation.contents))")

                        // Insurance / Marital Status Checkboxes
                        case "InsuredNo":
                            annotation.contents = (formData.insuredNo) ? "X" : ""
                            print("InsuredNo set to: \(String(describing: annotation.contents))")

                        case "MarriedYes":
                            annotation.contents = (formData.selectedMaritalStatus == "Married") ? "X" : ""
                            print("MarriedYes set to: \(String(describing: annotation.contents))")

                        case "SingleYes":
                            annotation.contents = (formData.selectedMaritalStatus == "Single") ? "X" : ""
                            print("SingleYes set to: \(String(describing: annotation.contents))")

                        case "SeparatedYes":
                            annotation.contents = (formData.selectedMaritalStatus == "Separated") ? "X" : ""
                            print("SeparatedYes set to: \(String(describing: annotation.contents))")

                        case "DivorcedYes":
                            annotation.contents = (formData.selectedMaritalStatus == "Divorced") ? "X" : ""
                            print("DivorcedYes set to: \(String(describing: annotation.contents))")

                        case "WidowedYes":
                            annotation.contents = (formData.selectedMaritalStatus == "Widowed") ? "X" : ""
                            print("WidowedYes set to: \(String(describing: annotation.contents))")
                        
                        case "ReasonForVisit":
                            annotation.contents = formData.reasonForVisit
                            print("ReasonForVisit set to: \(formData.reasonForVisit)")
                        
                        case "TotalIncomeField":
                            annotation.contents = formData.selectedIncome
                            print("IncomeField set to: \(formData.selectedIncome)")
                        
                        case "FamilySizeField":
                            annotation.contents = formData.selectedFamilySize
                            print("FamilySizeField set to: \(formData.selectedFamilySize)")


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
