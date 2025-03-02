import SwiftUI
import PencilKit

/// A SwiftUI wrapper around PencilKit's PKCanvasView.
struct SignatureCanvasView: UIViewRepresentable {
    @Binding var canvasView: PKCanvasView
    
    func makeUIView(context: Context) -> UIView {
        // Create a container view for the canvas + guidelines
        let containerView = UIView()
        containerView.backgroundColor = .white
        containerView.layer.borderColor = UIColor.lightGray.cgColor
        containerView.layer.borderWidth = 1.0
        containerView.layer.cornerRadius = 8.0
        
        // Add the PKCanvasView as a subview
        canvasView.backgroundColor = .clear
        canvasView.drawingPolicy = .anyInput
        canvasView.tool = PKInkingTool(.pen, color: .black, width: 5)
        canvasView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(canvasView)
        
        // Add constraints to fill the container
        NSLayoutConstraint.activate([
            canvasView.topAnchor.constraint(equalTo: containerView.topAnchor),
            canvasView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            canvasView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            canvasView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor)
        ])
        
        // Add dashed line (repositioned in updateUIView)
        let dashedLineLayer = CAShapeLayer()
        dashedLineLayer.strokeColor = UIColor.gray.cgColor
        dashedLineLayer.lineWidth = 1.0
        dashedLineLayer.lineDashPattern = [4, 4]
        containerView.layer.addSublayer(dashedLineLayer)
        context.coordinator.dashedLineLayer = dashedLineLayer
        
        return containerView
    }
    
    func updateUIView(_ containerView: UIView, context: Context) {
        // Update dashed line position whenever the container's bounds change
        guard let dashedLine = context.coordinator.dashedLineLayer else { return }
        let yPosition = containerView.bounds.height - 40 // Place near bottom
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 20, y: yPosition))
        path.addLine(to: CGPoint(x: containerView.bounds.width - 20, y: yPosition))
        dashedLine.path = path.cgPath
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator {
        var dashedLineLayer: CAShapeLayer?
    }
}
