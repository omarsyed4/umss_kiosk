//
//  DocumentPickerDelegate.swift
//  UMSS
//
//  Created by Omar Syed on 2/9/25.
//


import SwiftUI
import UIKit

public class DocumentPickerDelegate: NSObject, UIDocumentPickerDelegate, ObservableObject {
    public var completion: (([URL]) -> Void)?
    
    public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        completion?(urls)
    }
    
    public func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        completion?([])
    }
}
