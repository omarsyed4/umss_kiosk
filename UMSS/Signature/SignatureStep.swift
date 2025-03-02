import SwiftUI
import PencilKit

struct SignatureStep: View {
    /// Holds the user's signature image.
    @Binding var signatureImage: UIImage?
    
    // PencilKit canvas state
    @State private var canvasView = PKCanvasView()
    
    // Sample disclaimer text
    private let disclaimerText = """
    DISCLAIMER OF MEDICAL INFORMATION AUTHORIZATION:
    
    I have read and understand the Alert for Electronic Communications and agree that e-mail messages may include protected health information about me/the patient whenever necessary.
    
    My signature on this Authorization indicates that I am giving permission for the uses and disclosures of the protected health information described above. The facility, its employees, officers, and physicians are hereby released from any legal responsibility or liability for disclosures of the above information to the extent indicated and authorized herein.
    
    I understand this authorization may be revoked in writing at any time, except to the extent that action has been taken in reliance on this authorization. Unless otherwise revoked in writing, this authorization will expire 1 year from the date of execution.
    
    
    The patient information requested above may not be further disclosed to any party under any circumstances except with the patient's express
    written consent or as otherwise permitted by law. The information may not be used except for the need specified above.
    
    LIABILITY WAIVER: This liability waiver is a LEGAL DOCUMENT. This liability waiver is a "catch all". By signing this waiver, you or your
    representative acknowledge that you or your representative WILL NOT seek civil or federal penalties or compensation in any court in the event
    of injury or death incurred while in the facility/facility premises against the aforementioned owner / tenant of the facility.
    To the best of my knowledge the above information is complete and accurate.
    
    I have read and understand the HIPAA/Privacy Policy for United Medical and Social Services Clinic.
    
    I authorize United Medical and Social Services Clinic to obtain/have access to my medication history
    
    I authorize my provider's office to contact me by mobile phone.
    """
    
    var body: some View {
        VStack(spacing: 20) {
            // Scrollable disclaimer text
            ScrollView {
                Text(disclaimerText)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .padding()
            }
            .frame(height: 300)  // Adjust height as needed
            .background(Color(.systemGray6))
            .cornerRadius(8)
            .padding(.horizontal)
            
            // Signature label
            Text("Signature")
                .font(.title2)
                .fontWeight(.semibold)
            
            // Signature Canvas (non-scrollable)
            SignatureCanvasView(canvasView: $canvasView)
                .frame(height: 170)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                .padding(.horizontal)
            
            // Buttons to handle the drawing
            HStack(spacing: 20) {
                ActionButton(
                    title: "Clear",
                    iconName: "trash",
                    backgroundColor: Color.red.opacity(0.2),
                    foregroundColor: .red
                ) {
                    // Clears the canvas
                    canvasView.drawing = PKDrawing()
                }
                
                ActionButton(
                    title: "Save Signature",
                    iconName: "square.and.arrow.down",
                    backgroundColor: Color.blue.opacity(0.2),
                    foregroundColor: .blue
                ) {
                    // Extract an image from the drawing and store it
                    let image = canvasView.drawing.image(from: canvasView.bounds, scale: 1.0)
                    signatureImage = image
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 30)
        }
        .frame(maxWidth: .infinity)
        .background(Color.white.ignoresSafeArea())
    }
}
