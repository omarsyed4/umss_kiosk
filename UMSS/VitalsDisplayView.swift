import SwiftUI

struct VitalsDisplayView: View {
    let vitalsData: [String: Any]
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Basic vitals section
                VitalsCardView(title: "Basic Vitals", systemImage: "heart.fill") {
                LazyVGrid(
                    columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ],
                    spacing: 20
                ) {
                        // Height and Weight
                        if let height = vitalsData["height"] as? Int {
                            VitalItemView(
                                title: "Height",
                                value: "\(height)",
                                unit: "cm",
                                icon: "ruler",
                                color: .blue
                            )
                        }
                        
                        if let weight = vitalsData["weight"] as? Int {
                            VitalItemView(
                                title: "Weight",
                                value: "\(weight)",
                                unit: "kg",
                                icon: "scalemass",
                                color: .blue
                            )
                        }
                        
                        // Temperature
                        if let temperature = vitalsData["temperature"] as? Double {
                            VitalItemView(
                                title: "Temperature",
                                value: String(format: "%.1f", temperature),
                                unit: "°F",
                                icon: "thermometer",
                                color: .red
                            )
                        }
                        
                        // Heart rate
                        if let heartRate = vitalsData["heartRate"] as? Int {
                            VitalItemView(
                                title: "Heart Rate",
                                value: "\(heartRate)",
                                unit: "bpm",
                                icon: "heart",
                                color: .red
                            )
                        }
                        
                        // Respiratory rate
                        if let respiratoryRate = vitalsData["respiratoryRate"] as? Int {
                            VitalItemView(
                                title: "Respiratory Rate",
                                value: "\(respiratoryRate)",
                                unit: "bpm",
                                icon: "lungs",
                                color: .blue
                            )
                        }
                        
                        // Blood pressure
                        if let bloodPressure = vitalsData["bloodPressure"] as? Int {
                            VitalItemView(
                                title: "Blood Pressure",
                                value: "\(bloodPressure)",
                                unit: "mmHg",
                                icon: "waveform.path.ecg",
                                color: .red
                            )
                        }
                        
                        // SpO2
                        if let spo2 = vitalsData["spo2"] as? Int {
                            VitalItemView(
                                title: "SpO₂",
                                value: "\(spo2)",
                                unit: "%",
                                icon: "lungs.fill",
                                color: .blue
                            )
                        }
                        
                        // Glucose
                        if let glucose = vitalsData["glucose"] as? Int {
                            VitalItemView(
                                title: "Glucose",
                                value: "\(glucose)",
                                unit: "mg/dL",
                                icon: "drop",
                                color: .purple
                            )
                        }
                        
                        // Pain level
                        if let painLevel = vitalsData["painLevel"] as? Int {
                            VitalItemView(
                                title: "Pain Level",
                                value: "\(painLevel)",
                                unit: "/10",
                                icon: "face.smiling",
                                color: .orange
                            )
                        }
                    }
                }
                
                // Chief complaint section
                VitalsCardView(title: "Chief Complaint", systemImage: "text.bubble") {
                    if let chiefComplaint = vitalsData["chiefComplaint"] as? String {
                        Text(chiefComplaint)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                    } else {
                        Text("No chief complaint recorded")
                            .italic()
                            .foregroundColor(.secondary)
                    }
                }
                
                // Allergies section
                VitalsCardView(title: "Allergies", systemImage: "exclamationmark.shield") {
                    if let allergies = vitalsData["allergies"] as? String {
                        Text(allergies)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                    } else {
                        Text("No allergies recorded")
                            .italic()
                            .foregroundColor(.secondary)
                    }
                }
                
                // Medical history section
                VitalsCardView(title: "Medical History", systemImage: "list.clipboard") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Self Medical History:")
                            .font(.headline)
                        
                        if let selfHistory = vitalsData["selfMedicalHistory"] as? [String], !selfHistory.isEmpty {
                            ForEach(selfHistory, id: \.self) { condition in
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                    Text(condition)
                                }
                            }
                        } else {
                            Text("None recorded")
                                .italic()
                                .foregroundColor(.secondary)
                        }
                        
                        Divider()
                            .padding(.vertical, 8)
                        
                        Text("Family Medical History:")
                            .font(.headline)
                        
                        if let familyHistory = vitalsData["familyMedicalHistory"] as? [String], !familyHistory.isEmpty {
                            ForEach(familyHistory, id: \.self) { condition in
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.blue)
                                    Text(condition)
                                }
                            }
                        } else {
                            Text("None recorded")
                                .italic()
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }
                
                // Recent travel/illness section
                VitalsCardView(title: "Recent Travel & Illness", systemImage: "airplane") {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Recent Travel:")
                                .font(.headline)
                            
                            if let recentTravel = vitalsData["recentTravel"] as? Bool {
                                Text(recentTravel ? "Yes" : "No")
                                    .foregroundColor(recentTravel ? .red : .green)
                                    .fontWeight(.bold)
                            } else {
                                Text("Not recorded")
                                    .italic()
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        HStack {
                            Text("Recent Illness:")
                                .font(.headline)
                            
                            if let recentIllness = vitalsData["recentIllness"] as? String, !recentIllness.isEmpty {
                                Text(recentIllness)
                                    .foregroundColor(.red)
                                    .fontWeight(.bold)
                            } else {
                                Text("None")
                                    .foregroundColor(.green)
                                    .fontWeight(.bold)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }
                
                // Medications section
                VitalsCardView(title: "Medications", systemImage: "pill") {
                    if let medications = vitalsData["medications"] as? [[String: Any]], !medications.isEmpty {
                        VStack(spacing: 12) {
                            ForEach(0..<medications.count, id: \.self) { index in
                                let medication = medications[index]
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(medication["name"] as? String ?? "Unknown Medication")
                                        .font(.headline)
                                        .foregroundColor(.blue)
                                    
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text("Dosage:")
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                            Text(medication["dosage"] as? String ?? "Not specified")
                                                .font(.body)
                                        }
                                        
                                        Spacer()
                                        
                                        VStack(alignment: .leading) {
                                            Text("Frequency:")
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                            Text(medication["frequency"] as? String ?? "Not specified")
                                                .font(.body)
                                        }
                                        
                                        Spacer()
                                        
                                        VStack(alignment: .leading) {
                                            Text("Start Date:")
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                            Text(medication["startDate"] as? String ?? "Not specified")
                                                .font(.body)
                                        }
                                    }
                                }
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(8)
                                
                                if index < medications.count - 1 {
                                    Divider()
                                }
                            }
                        }
                    } else {
                        Text("None")
                            .italic()
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
                
                // Surgical History section
                VitalsCardView(title: "Surgical History", systemImage: "scissors") {
                    if let surgicalHistory = vitalsData["surgicalHistory"] as? [[String: String]], !surgicalHistory.isEmpty {
                        VStack(spacing: 12) {
                            ForEach(0..<surgicalHistory.count, id: \.self) { index in
                                let surgery = surgicalHistory[index]
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(surgery["surgery"] ?? "Unknown Surgery")
                                        .font(.headline)
                                        .foregroundColor(.purple)
                                    
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text("Reason:")
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                            Text(surgery["reason"] ?? "Not specified")
                                                .font(.body)
                                        }
                                        
                                        Spacer()
                                        
                                        VStack(alignment: .leading) {
                                            Text("Year:")
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                            Text(surgery["year"] ?? "Not specified")
                                                .font(.body)
                                        }
                                        
                                        Spacer()
                                        
                                        VStack(alignment: .leading) {
                                            Text("Hospital:")
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                            Text(surgery["hospital"] ?? "Not specified")
                                                .font(.body)
                                        }
                                    }
                                }
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.purple.opacity(0.1))
                                .cornerRadius(8)
                                
                                if index < surgicalHistory.count - 1 {
                                    Divider()
                                }
                            }
                        }
                    } else {
                        Text("None")
                            .italic()
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
                
                // Assessment and Plans section
                if let assessmentPlans = vitalsData["assessmentPlans"] as? String, !assessmentPlans.isEmpty {
                    VitalsCardView(title: "Assessment & Plans", systemImage: "note.text") {
                        Text(assessmentPlans)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Vitals Report")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
            }
        }
    }
}

// Helper view for vitals cards
struct VitalsCardView<Content: View>: View {
    let title: String
    let systemImage: String
    let content: Content
    
    init(title: String, systemImage: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.systemImage = systemImage
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: systemImage)
                    .font(.title3)
                    .foregroundColor(UMSSBrand.navy)
                
                Text(title)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(UMSSBrand.navy)
            }
            .padding(.bottom, 4)
            
            content
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

// Helper view for individual vital measurements
struct VitalItemView: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.headline)
                .foregroundColor(.secondary)
            
            HStack(alignment: .center) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(unit)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

struct VitalsDisplayView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleData: [String: Any] = [
            "height": 175,
            "weight": 70,
            "temperature": 98.6,
            "heartRate": 72,
            "respiratoryRate": 16,
            "bloodPressure": 120,
            "spo2": 98,
            "glucose": 100,
            "painLevel": 2,
            "chiefComplaint": "Persistent cough and mild fever for 3 days",
            "allergies": "Penicillin, Shellfish",
            "selfMedicalHistory": ["Hypertension", "Asthma"],
            "familyMedicalHistory": ["Diabetes", "Heart Disease"],
            "recentTravel": true,
            "recentIllness": "Fever",
            "medications": [
                ["name": "Lisinopril", "dosage": "10mg", "frequency": "Daily", "startDate": "01/15/2023"],
                ["name": "Albuterol", "dosage": "90mcg", "frequency": "As needed", "startDate": "03/10/2023"]
            ],
            "surgicalHistory": [
                ["surgery": "Appendectomy", "reason": "Appendicitis", "year": "2010", "hospital": "University Hospital"]
            ],
            "assessmentPlans": "Continue current medications. Follow up in 3 months."
        ]
        
        return VitalsDisplayView(vitalsData: sampleData)
    }
}
