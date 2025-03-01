//
//  AppointmentComponents.swift
//  UMSS
//
//  Created by Omar Syed
//

import SwiftUI

struct AppointmentListView: View {
    let appointments: [Appointment]
    @State private var selectedAppointment: Appointment?
    var onAppointmentSelected: ((Appointment) -> Void)?
    
    // Group appointments by booked status
    private var bookedAppointments: [Appointment] {
        appointments.filter { $0.booked == "true" }
    }
    
    private var availableAppointments: [Appointment] {
        appointments.filter { $0.booked == "false" }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            // Booked appointments section
            if !bookedAppointments.isEmpty {
                Text("Booked Appointments")
                    .font(.headline)
                    .foregroundColor(.blue)
                    .padding(.top, 5)
                
                ForEach(bookedAppointments) { appointment in
                    AppointmentRow(
                        appointment: appointment,
                        isSelected: selectedAppointment?.id == appointment.id
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedAppointment = appointment
                        onAppointmentSelected?(appointment)
                    }
                }
            }
            
            // Available slots section
            if !availableAppointments.isEmpty {
                Text("Available Slots (For Walk-ins)")
                    .font(.headline)
                    .foregroundColor(.green)
                    .padding(.top, 10)
                
                ForEach(availableAppointments) { appointment in
                    AppointmentRow(
                        appointment: appointment,
                        isSelected: selectedAppointment?.id == appointment.id
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedAppointment = appointment
                        onAppointmentSelected?(appointment)
                    }
                }
            }
        }
    }
}

struct AppointmentRow: View {
    let appointment: Appointment
    var isSelected: Bool = false
    
    var statusColor: Color {
        if isSelected {
            return .blue
        } else if appointment.booked == "true" {
            return .orange
        } else {
            return .green
        }
    }
    
    var statusText: String {
        if appointment.booked == "true" {
            return "Booked"
        } else {
            return "Available"
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
                if appointment.booked == "true" && !appointment.patientId.isEmpty {
                    Text("Patient #\(appointment.patientId)")
                        .font(.body)
                    Text(statusText)
                        .font(.caption)
                        .foregroundColor(statusColor)
                } else {
                    Text(statusText)
                        .font(.body)
                        .foregroundColor(statusColor)
                }
            }
            
            Spacer()
            
            // Status indicators
            HStack(spacing: 4) {
                if appointment.isCheckedIn == "true" {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                }
                
                if appointment.seenDoctor == "true" {
                    Image(systemName: "stethoscope")
                        .foregroundColor(.blue)
                        .font(.caption)
                }
                
                if appointment.vitalsDone == "true" {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.blue.opacity(0.1) : Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Color.blue : statusColor.opacity(0.3), lineWidth: isSelected ? 2 : 1)
        )
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}
