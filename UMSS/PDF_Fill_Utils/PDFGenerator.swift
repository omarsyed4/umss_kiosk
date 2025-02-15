import PDFKit
import UIKit

class PDFGenerator {
    static func fillPDF(pdfDocument: PDFDocument, with formData: PatientForm) {
        let pageCount = pdfDocument.pageCount
        if pageCount == 0 { return }
        
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
                    case "MaritalStatusField":
                        annotation.contents = formData.selectedMaritalStatus
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
                    case "FullAddress":
                        annotation.contents = formData.rawAddress
                    case "CityStateField":
                        annotation.contents = formData.cityState
                    case "Date":
                        annotation.contents = formData.date
                    case "AgeField":
                        annotation.contents = formData.age
                        
                    // Gender Checkboxes
                    case "MaleCheck":
                        annotation.contents = formData.isMale ? "X" : ""
                    case "FemaleCheck":
                        annotation.contents = formData.isFemale ? "X" : ""
                        
                    // New Patient Checkboxes
                    case "NewPatientNo":
                        annotation.contents = formData.isExistingPatient ? "X" : ""
                    case "NewPatientYes":
                        annotation.contents = formData.isExistingPatient ? "" : "X"
                        
                    // Race Checkboxes
                    case "WhiteCheck":
                        annotation.contents = formData.isWhite ? "X" : ""
                    case "BlackCheck":
                        annotation.contents = formData.isBlack ? "X" : ""
                    case "AsianCheck":
                        annotation.contents = formData.isAsian ? "X" : ""
                    case "AmIndianCheck":
                        annotation.contents = formData.isAmIndian ? "X" : ""
                        
                    // Ethnicity Checkboxes
                    case "HispanicCheck":
                        annotation.contents = formData.isHispanic ? "X" : ""
                    case "NonHispanicCheck":
                        annotation.contents = formData.isNonHispanic ? "X" : ""
                        
                    // Insurance / Marital Status Checkboxes
                    case "InsuredNo":
                        annotation.contents = formData.insuredNo ? "X" : ""
                    case "MarriedYes":
                        annotation.contents = (formData.selectedMaritalStatus == "Married") ? "X" : ""
                    case "SingleYes":
                        annotation.contents = (formData.selectedMaritalStatus == "Single") ? "X" : ""
                    case "SeparatedYes":
                        annotation.contents = (formData.selectedMaritalStatus == "Separated") ? "X" : ""
                    case "DivorcedYes":
                        annotation.contents = (formData.selectedMaritalStatus == "Divorced") ? "X" : ""
                    case "WidowedYes":
                        annotation.contents = (formData.selectedMaritalStatus == "Widowed") ? "X" : ""
                        
                    case "ReasonForVisit":
                        annotation.contents = formData.reasonForVisit
                    case "TotalIncomeField":
                        annotation.contents = formData.selectedIncome
                    case "FamilySizeField":
                        annotation.contents = formData.selectedFamilySize
                        
                    default:
                        print("[WARNING] No matching case for field: \(fieldName)")
                    }
                    
                    // Update the annotation to reflect the changes
                    annotation.widgetStringValue = annotation.contents ?? ""
                    annotation.setValue((annotation.contents ?? "") as NSString, forAnnotationKey: .widgetValue)
                }
            }
        }
    }
    
    static func addSignatureImage(pdfDocument: PDFDocument, signatureImage: UIImage?) {
        guard let sigImage = signatureImage else { return }
        
        let signatureBoundsPerPage: [Int: [CGRect]] = [
            1: [CGRect(x: 105, y: 500, width: 100, height: 25)],
            2: [CGRect(x: 80, y: 70, width: 100, height: 25)],
            3: [
                CGRect(x: 220, y: 350, width: 100, height: 25),
                CGRect(x: 105, y: 210, width: 100, height: 25),
                CGRect(x: 105, y: 135, width: 100, height: 25),
                CGRect(x: 105, y: 87, width: 100, height: 25),
                CGRect(x: 105, y: 45, width: 100, height: 25)
            ]
        ]
        
        for (pageIndex, boundsArray) in signatureBoundsPerPage {
            guard let page = pdfDocument.page(at: pageIndex) else { continue }
            for bounds in boundsArray {
                let stampAnnotation = StampAnnotation(bounds: bounds, image: sigImage)
                page.addAnnotation(stampAnnotation)
            }
        }
    }
}

class StampAnnotation: PDFAnnotation {
    let stampImage: UIImage
    
    init(bounds: CGRect, image: UIImage) {
        self.stampImage = image
        super.init(bounds: bounds, forType: .stamp, withProperties: nil)
        self.border = PDFBorder()
        self.border?.lineWidth = 0
        self.color = .clear
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(with box: PDFDisplayBox, in context: CGContext) {
        guard let cgImage = stampImage.cgImage else { return }
        context.saveGState()
        context.translateBy(x: bounds.minX, y: bounds.minY)
        let drawingRect = CGRect(origin: .zero, size: bounds.size)
        context.draw(cgImage, in: drawingRect)
        context.restoreGState()
    }
}