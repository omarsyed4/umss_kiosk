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
    @State private var showContinueButton: Bool = false  // Add state for button visibility
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
        VStack(alignment: .leading, spacing: 20) {
            // Booked appointments section
            if !bookedAppointments.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
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
                            
                            // Show continue button with animation when appointment is selected
                            withAnimation(.easeIn(duration: 0.5)) {
                                showContinueButton = true
                            }
                        }
                        .onAppear {
                            print("DEBUG: Displayed booked appointment row: \(appointment.id) with patient \(appointment.patientId)")
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(15)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
            } else {
                VStack(alignment: .leading) {
                    Text("No booked appointments")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .onAppear {
                            print("DEBUG: No booked appointments to display")
                        }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemGray6))
                .cornerRadius(15)
            }
            
            // Walk-in Appointment section - always visible
            VStack(alignment: .leading, spacing: 12) {
                Text("Create Walk-in Appointment")
                    .font(.headline)
                    .foregroundColor(.green)
                    .padding(.top, 5)
                
                // Create a custom button that looks like an appointment row
                Button(action: {
                    // Create a new appointment with current time
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "h:mm a"
                    let currentTimeString = dateFormatter.string(from: Date())
                    
                    // Date formatter for the date parameter
                    let dateOnlyFormatter = DateFormatter()
                    dateOnlyFormatter.dateFormat = "yyyy-MM-dd"
                    let currentDateString = dateOnlyFormatter.string(from: Date())
                    
                    // Create a new appointment with a unique ID
                    let newAppointment = Appointment(
                        id: UUID().uuidString,
                        time: currentTimeString,
                        date: currentDateString,  // Convert Date to String
                        patientId: "", // Will be filled after patient registration
                        patientName: "",  // Empty string instead of nil
                        booked: true, // Mark as booked immediately
                        isCheckedIn: false,
                        seenDoctor: false,
                        vitalsDone: false
                    )
                    
                    print("DEBUG: Created new walk-in appointment at \(currentTimeString)")
                    selectedAppointment = newAppointment
                    onAppointmentSelected?(newAppointment)
                    
                    // Show continue button with animation
                    withAnimation(.easeIn(duration: 0.5)) {
                        showContinueButton = true
                    }
                }) {
                    HStack {
                        Text(DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .short))
                            .font(.headline)
                            .foregroundColor(.primary)
                            .frame(width: 80, alignment: .leading)
                        
                        Divider()
                            .frame(height: 30)
                        VStack(alignment: .leading) {
                            Text("Available Now")
                                .font(.body)
                                .foregroundColor(.green)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.green)
                            .font(.system(size: 18))
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    )
                }
                
                Text("Create an immediate walk-in appointment for the current time")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.bottom, 5)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(15)
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
            
            // Continue Button that fades in
            if showContinueButton, let selected = selectedAppointment {
                Button(action: {
                    // Call the appointment selected handler with the selected appointment
                    onAppointmentSelected?(selected)
                }) {
                    Text(selected.booked ? "Continue with Patient Data" : "Continue as Walk-in")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.blue)
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                }
                .padding(.top, 20)
                .transition(.opacity)
            }
        }
        .padding(.horizontal)
        .onAppear {
            print("DEBUG: AppointmentListView appeared")
            print("DEBUG: Total appointments: \(appointments.count)")
            print("DEBUG: Booked appointments: \(bookedAppointments.count)")
            print("DEBUG: Available appointments: \(availableAppointments.count)")
        }
        .animation(.easeInOut, value: selectedAppointment != nil)
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
                
                if let vitals = appointment.vitalsDone, vitals {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.red)
                        .font(.caption)
                }
                
                if appointment.seenDoctor {
                    Image(systemName: "stethoscope")
                        .foregroundColor(.blue)
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
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(isSelected ? Color.blue : Color(.systemGray4), lineWidth: isSelected ? 2 : 1)
        )
        .animation(.easeInOut(duration: 0.2), value: isSelected)
        .onAppear {
            print("DEBUG: Rendered appointment row \(appointment.id) - Time: \(appointment.time), Status: \(statusText)")
        }
    }
}
