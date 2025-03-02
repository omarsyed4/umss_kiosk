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
    
    init(appointments: [Appointment], onAppointmentSelected: ((Appointment) -> Void)? = nil) {
        self.appointments = appointments
        self.onAppointmentSelected = onAppointmentSelected
        print("DEBUG: AppointmentListView initialized with \(appointments.count) appointments")
        print("DEBUG: Raw appointments data: \(appointments)")
    }
    
    // Group appointments by booked status using boolean checks
    private var bookedAppointments: [Appointment] {
        print("DEBUG: Filtering booked appointments...")
        let booked = appointments.filter { appointment in
            print("DEBUG: Evaluating appointment \(appointment.id) - booked bool: \(appointment.booked)")
            return appointment.booked
        }
        print("DEBUG: Found \(booked.count) booked appointments")
        return booked
    }
    
    private var availableAppointments: [Appointment] {
        print("DEBUG: Filtering available appointments...")
        let available = appointments.filter { appointment in
            print("DEBUG: Evaluating appointment \(appointment.id) - booked bool: \(appointment.booked)")
            return !appointment.booked
        }
        print("DEBUG: Found \(available.count) available appointments")
        return available
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            // Booked appointments section
            if !bookedAppointments.isEmpty {
                Text("Booked Appointments")
                    .font(.headline)
                    .foregroundColor(.blue)
                    .padding(.top, 5)
                    .onAppear {
                        print("DEBUG: Rendering booked appointments section with \(bookedAppointments.count) appointments")
                    }
                
                ForEach(bookedAppointments) { appointment in
                    AppointmentRow(
                        appointment: appointment,
                        isSelected: selectedAppointment?.id == appointment.id
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        print("DEBUG: Selected booked appointment: \(appointment.id) at \(appointment.time)")
                        selectedAppointment = appointment
                        onAppointmentSelected?(appointment)
                    }
                    .onAppear {
                        print("DEBUG: Displayed booked appointment row: \(appointment.id) with patient \(appointment.patientId)")
                    }
                }
            } else {
                Text("No booked appointments")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .onAppear {
                        print("DEBUG: No booked appointments to display")
                    }
            }
            
            // Next Available Slot section (instead of showing all available slots)
            if !availableAppointments.isEmpty {
                Text("Next Available Slot")
                    .font(.headline)
                    .foregroundColor(.green)
                    .padding(.top, 10)
                    .onAppear {
                        print("DEBUG: Rendering next available slot from \(availableAppointments.count) available appointments")
                    }
                
                // Only show the first available slot (assuming already sorted by time)
                let nextAvailable = availableAppointments.first!
                AppointmentRow(
                    appointment: nextAvailable,
                    isSelected: selectedAppointment?.id == nextAvailable.id
                )
                .contentShape(Rectangle())
                .onTapGesture {
                    print("DEBUG: Selected next available appointment: \(nextAvailable.id) at \(nextAvailable.time)")
                    selectedAppointment = nextAvailable
                    onAppointmentSelected?(nextAvailable)
                }
                .onAppear {
                    print("DEBUG: Displayed next available slot: \(nextAvailable.id) at time \(nextAvailable.time)")
                }
                .padding(.bottom, 5)
                
                Text("Tap to select this slot for a walk-in appointment")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.bottom, 10)
            } else {
                Text("No available slots")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .onAppear {
                        print("DEBUG: No available appointments to display")
                    }
            }
        }
        .onAppear {
            print("DEBUG: AppointmentListView appeared")
            print("DEBUG: Total appointments: \(appointments.count)")
            print("DEBUG: Booked appointments: \(bookedAppointments.count)")
            print("DEBUG: Available appointments: \(availableAppointments.count)")
        }
    }
}

struct AppointmentRow: View {
    let appointment: Appointment
    var isSelected: Bool = false
    
    init(appointment: Appointment, isSelected: Bool = false) {
        self.appointment = appointment
        self.isSelected = isSelected
        print("DEBUG: AppointmentRow initialized - ID: \(appointment.id), Time: \(appointment.time), Booked: \(appointment.booked)")
        print("DEBUG: Appointment details - PatientID: \(appointment.patientId), CheckedIn: \(appointment.isCheckedIn), Vitals: \(appointment.vitalsDone), SeenDoctor: \(appointment.seenDoctor)")
    }
    
    // Determine the text and color based on the boolean 'booked'
    private var statusText: String {
        appointment.booked ? "Booked" : "Available"
    }
    
    private var statusColor: Color {
        appointment.booked ? .orange : .green
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
                if appointment.booked, appointment.patientName != nil {
                    Text(appointment.patientName ?? "Unknown")
                        .font(.headline)
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
                if appointment.isCheckedIn {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                }
                
                if appointment.seenDoctor {
                    Image(systemName: "stethoscope")
                        .foregroundColor(.blue)
                        .font(.caption)
                }
                
                if let vitals = appointment.vitalsDone, vitals {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.red)
                        .font(.caption)
                }
                
                // Add selection checkmark
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                        .font(.system(size: 18))
                        .padding(.leading, 4)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Color.blue : Color(.systemGray4), lineWidth: isSelected ? 2 : 1)
        )
        .animation(.easeInOut(duration: 0.2), value: isSelected)
        .onAppear {
            print("DEBUG: Rendered appointment row \(appointment.id) - Time: \(appointment.time), Status: \(statusText)")
        }
    }
}
