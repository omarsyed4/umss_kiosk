//
//  StringFormatters.swift
//  UMSS
//
//  Created by GitHub Copilot
//

import Foundation

/// Formats a string of digits into (XXX) XXX-XXXX format.
/// Usage: formatPhoneNumber("1234567890") -> "(123) 456-7890"
public func formatPhoneNumber(_ number: String) -> String {
    // Limit to maximum 10 digits
    let maxDigits = String(number.prefix(10))
    let count = maxDigits.count
    
    switch count {
    case 0...3:
        return maxDigits
    case 4...6:
        let area = maxDigits.prefix(3)
        let prefix = maxDigits.suffix(count - 3)
        return "(\(area)) \(prefix)"
    default:
        let area = maxDigits.prefix(3)
        let prefix = maxDigits.dropFirst(3).prefix(3)
        let lineNumber = maxDigits.dropFirst(6)
        return "(\(area)) \(prefix)-\(lineNumber)"
    }
}
