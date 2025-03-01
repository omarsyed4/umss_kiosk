//
//  AppointmentComponents.swift
//  UMSS
//
//  Created by Omar Syed
//

import SwiftUI

struct AppointmentListView: View {
    let appointments: [Appointment]
    
    var body: some View {
        VStack(spacing: 10) {
            ForEach(appointments) { appointment in
                AppointmentRow(appointment: appointment)
            }
        }
    }
}

struct AppointmentRow: View {
    let appointment: Appointment
    
    var statusColor: Color {
        switch appointment.status.lowercased() {
        case "available":
            return .green
        case "booked":
            return .blue
        case "cancelled":
            return .red
        default:
            return .gray
        }
    }
    
    var body: some View {
        HStack {
            Text(appointment.time)
                .font(.headline)
                .foregroundColor(.primary)
                .frame(width: 80, alignment: .leading)
            
            Divider()
                .frame(height: 30)
            
            VStack(alignment: .leading) {
                if let patientName = appointment.patientName, !patientName.isEmpty {
                    Text(patientName)
                        .font(.body)
                    Text(appointment.status)
                        .font(.caption)
                        .foregroundColor(statusColor)
                } else {
                    Text(appointment.status)
                        .font(.body)
                        .foregroundColor(statusColor)
                }
                
                if let notes = appointment.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(statusColor.opacity(0.3), lineWidth: 1)
        )
    }
}
