import SwiftUI

struct VitalsStepView: View {
    let onComplete: ([String: Any]) -> Void
    @ObservedObject var patientModel: PatientModel
    
    @State private var currentSlide: Int = 0

    // Slide 1: Height and Weight pickers
    @State private var selectedHeight: Int = 170
    @State private var selectedWeight: Int = 70
    let heights = Array(100...250)
    let weights = Array(30...150)

    // Slide 1: Additional Sliders
    @State private var temperature: Double = 98.6
    @State private var respiratoryRate: Double = 12
    @State private var bloodPressure: Double = 120
    @State private var spo2: Double = 98
    @State private var heartRate: Double = 70
    @State private var glucose: Double = 100

    // Slide 2: Chief Complaint
    @State private var chiefComplaint: String = ""

    // Slide 3: Pain indicator + Recent Travel/Illness
    @State private var painLevel: Double = 5
    @State private var recentTravel: Bool = false
    @State private var recentIllnessSelection: String = ""

    // Slide 4: Allergies
    @State private var allergies: String = ""
    @State private var noAllergies: Bool = false

    // Slide 5: Recent Hospitalizations
    @State private var hospitalizations: String = ""
    @State private var noHospitalizations: Bool = false
    
    // Slide 6: Medications
    @State private var medications: [Medication] = [Medication()]

    // Slide 7: Medical / Family History
    @State private var selfMedicalHistory: [String] = []
    @State private var familyMedicalHistory: [String] = []

    // NEW: Slide 8: Surgical History + Assessment
    @State private var surgicalHistory: [SurgicalHistory] = [SurgicalHistory()]
    @State private var assessmentPlans: String = ""


    // Medication data structure
    struct Medication: Identifiable {
        var id = UUID()
        var name: String = ""
        var dosage: String = ""
        var frequency: String = ""
        var startDate: Date = Date()
    }

    // MARK: - Data structure for Surgical History
    struct SurgicalHistory: Identifiable {
        var id = UUID()
        var surgery: String = ""
        var reason: String = ""
        var year: String = ""
        var hospital: String = ""
    }


    var body: some View {
        VStack {
            Spacer()

            Group {
                if currentSlide == 0 {
                    // Slide 1
                    heightWeightVitalsSlide
                } else if currentSlide == 1 {
                    // Slide 2
                    chiefComplaintSlide
                } else if currentSlide == 2 {
                    // Slide 3
                    painRecentTravelSlide
                } else if currentSlide == 3 {
                    // Slide 4
                    allergiesSlide
                } else if currentSlide == 4 {
                    // Slide 5
                    hospitalizationsSlide
                } else if currentSlide == 5 {
                    // Slide 6
                    medicationsSlide
                } else if currentSlide == 6 {
                    // Slide 7
                    medicalFamilyHistorySlide
                } else if currentSlide == 7 {
                    // Slide 8
                    surgicalHistorySlide
                }
            }            
            .padding()
            .animation(.easeInOut, value: currentSlide)

            Spacer()
            
            // Bottom navigation
            HStack {
                if currentSlide > 0 {
                    Button(action: {
                        withAnimation {
                            currentSlide -= 1
                        }
                    }) {
                        HStack {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .padding()
                        .background(Color.gray.opacity(0.3))
                        .cornerRadius(8)
                    }
                }
                
                Spacer()
                
                // If not on the last slide, show Next; otherwise Submit
                if currentSlide < 7 {
                    Button(action: {
                        withAnimation {
                            currentSlide += 1
                        }
                    }) {
                        HStack {
                            Text("Next")
                            Image(systemName: "chevron.right")
                        }
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                } else {
                    // Show Submit button on the last slide (7)
                    Button(action: submitForm) {
                        Text("Submit")
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding()
    }
    
    // MARK: - Slides
    
    private var heightWeightVitalsSlide: some View {
        VStack(spacing: 20) {
            Text("Select Your Height and Weight")
                .font(.title2)
                .fontWeight(.semibold)
            
            HStack(spacing: 40) {
                VStack {
                    Text("Height (cm)")
                        .font(.subheadline)
                    Picker("Height", selection: $selectedHeight) {
                        ForEach(heights, id: \.self) { height in
                            Text("\(height)")
                        }
                    }
                    .pickerStyle(WheelPickerStyle())
                    .frame(maxWidth: 100)
                }
                
                VStack {
                    Text("Weight (kg)")
                        .font(.subheadline)
                    Picker("Weight", selection: $selectedWeight) {
                        ForEach(weights, id: \.self) { weight in
                            Text("\(weight)")
                        }
                    }
                    .pickerStyle(WheelPickerStyle())
                    .frame(maxWidth: 100)
                }
            }
            
            // Sliders in a 2x3 grid:
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                VStack(alignment: .leading) {
                    Text("Temperature (°F): \(String(format: "%.1f", temperature))")
                    Slider(value: $temperature, in: 95...105, step: 0.1)
                }
                VStack(alignment: .leading) {
                    Text("Respiratory Rate: \(Int(respiratoryRate))")
                    Slider(value: $respiratoryRate, in: 10...40, step: 1)
                }
                VStack(alignment: .leading) {
                    Text("Blood Pressure: \(Int(bloodPressure))")
                    Slider(value: $bloodPressure, in: 80...200, step: 1)
                }
                VStack(alignment: .leading) {
                    Text("SpO₂: \(Int(spo2))%")
                    Slider(value: $spo2, in: 90...100, step: 1)
                }
                VStack(alignment: .leading) {
                    Text("Heart Rate: \(Int(heartRate))")
                    Slider(value: $heartRate, in: 40...150, step: 1)
                }
                VStack(alignment: .leading) {
                    Text("Glucose: \(Int(glucose))")
                    Slider(value: $glucose, in: 70...300, step: 1)
                }
            }
        }
    }
    
    private var chiefComplaintSlide: some View {
        VStack(spacing: 20) {
            Text("Chief Complaint")
                .font(.title2)
                .fontWeight(.semibold)
            TextEditor(text: $patientModel.reasonForVisit)
                .frame(height: 150)
                .padding()
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                )
        }
    }
    
    private var painRecentTravelSlide: some View {
        VStack(spacing: 20) {
            Text("Pain Indicator")
                .font(.title2)
                .fontWeight(.semibold)
            
            Slider(value: $painLevel, in: 1...10, step: 1)
            Text("Pain Level: \(Int(painLevel))")
                .font(.headline)
            
            Text("Recent Travel?")
                .font(.headline)
            
            ChoiceRow(
                title: "Yes",
                isSelected: recentTravel,
                action: { recentTravel = true }
            )
            ChoiceRow(
                title: "No",
                isSelected: !recentTravel,
                action: { recentTravel = false }
            )
            
            Text("Recent Illness?")
                .font(.headline)
            ChoiceRow(
                title: "Fever",
                isSelected: recentIllnessSelection == "Fever",
                action: { recentIllnessSelection = "Fever" }
            )
            ChoiceRow(
                title: "Cough",
                isSelected: recentIllnessSelection == "Cough",
                action: { recentIllnessSelection = "Cough" }
            )
            ChoiceRow(
                title: "Congestion",
                isSelected: recentIllnessSelection == "Congestion",
                action: { recentIllnessSelection = "Congestion" }
            )
            ChoiceRow(
                title: "None",
                isSelected: recentIllnessSelection == "None",
                action: { recentIllnessSelection = "None" }
            )
        }
    }
    
    private var allergiesSlide: some View {
        VStack(spacing: 20) {
            Text("Allergies")
                .font(.title2)
                .fontWeight(.semibold)
            TextEditor(text: $allergies)
                .frame(height: 150)
                .padding()
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                )
            Button(action: {
                noAllergies.toggle()
                if noAllergies {
                    allergies = "None"
                } else {
                    allergies = ""
                }
            }) {
                Text(noAllergies ? "Clear 'No Allergies'" : "No Allergies")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(8)
            }
        }
    }
    
    private var hospitalizationsSlide: some View {
        VStack(spacing: 20) {
            Text("Recent Hospitalizations")
                .font(.title2)
                .fontWeight(.semibold)
            TextEditor(text: $hospitalizations)
                .frame(height: 150)
                .padding()
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                )
            Button(action: {
                noHospitalizations.toggle()
                if noHospitalizations {
                    hospitalizations = "None"
                } else {
                    hospitalizations = ""
                }
            }) {
                Text(noHospitalizations ? "Clear 'No Recent Hospitalizations'" : "No Recent Hospitalizations")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(8)
            }
        }
    }
    
    private var medicationsSlide: some View {
        VStack(spacing: 20) {
            Text("Current Medications")
                .font(.title2)
                .fontWeight(.semibold)
            
            // Header row
            HStack {
                Text("Medication Name")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("Dosage")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("Frequency")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("Start Date")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("") // Empty space for delete button
                    .frame(width: 40)
            }
            .padding(.horizontal)
            
            ScrollView {
                VStack(spacing: 10) {
                    ForEach(Array(medications.enumerated()), id: \.element.id) { index, _ in
                        HStack {
                            TextField("Med name", text: $medications[index].name)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .frame(maxWidth: .infinity)
                            
                            TextField("Dose", text: $medications[index].dosage)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .frame(maxWidth: .infinity)
                            
                            TextField("Freq", text: $medications[index].frequency)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .frame(maxWidth: .infinity)
                            
                            DatePicker(
                                "",
                                selection: $medications[index].startDate,
                                displayedComponents: .date
                            )
                            .frame(maxWidth: .infinity)
                            .labelsHidden()
                            
                            Button(action: {
                                if medications.count > 1 {
                                    medications.remove(at: index)
                                }
                            }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                            .frame(width: 40)
                            .disabled(medications.count <= 1)
                        }
                    }
                }
                .padding(.horizontal)
            }
            .frame(height: 200)
            
            Button(action: {
                medications.append(Medication())
            }) {
                HStack {
                    Image(systemName: "plus.circle")
                    Text("Add Medication")
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue.opacity(0.2))
                .cornerRadius(8)
            }
        }
    }
    
    private var medicalFamilyHistorySlide: some View {
        VStack(spacing: 20) {
            Text("Medical / Family Health History")
                .font(.title2)
                .fontWeight(.semibold)
            
            // Self history
            VStack(alignment: .leading, spacing: 10) {
                Text("Self: Select all that apply")
                    .font(.headline)
                MultiSelectSearchView(
                    title: "Search or Select Condition",
                    allOptions: historyConditions,
                    selectedOptions: $selfMedicalHistory
                )
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
            
            // Family history
            VStack(alignment: .leading, spacing: 10) {
                Text("Family: Select all that apply")
                    .font(.headline)
                MultiSelectSearchView(
                    title: "Search or Select Condition",
                    allOptions: historyConditions,
                    selectedOptions: $familyMedicalHistory
                )
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
        }
    }

    private var surgicalHistorySlide: some View {
        VStack(spacing: 20) {
            Text("Surgical History")
                .font(.title2)
                .fontWeight(.semibold)
            
            // Header row
            HStack {
                Text("Surgery")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("Reason")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("Year")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("Hospital")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("") // Empty space for delete button
                    .frame(width: 40)
            }
            .padding(.horizontal)
            
            // Scrollable list of surgeries
            ScrollView {
                VStack(spacing: 10) {
                    ForEach(Array(surgicalHistory.enumerated()), id: \.element.id) { index, _ in
                        HStack {
                            TextField("Surgery", text: $surgicalHistory[index].surgery)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .frame(maxWidth: .infinity)
                            
                            TextField("Reason", text: $surgicalHistory[index].reason)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .frame(maxWidth: .infinity)
                            
                            TextField("Year", text: $surgicalHistory[index].year)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .frame(maxWidth: .infinity)
                            
                            TextField("Hospital", text: $surgicalHistory[index].hospital)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .frame(maxWidth: .infinity)
                            
                            Button(action: {
                                if surgicalHistory.count > 1 {
                                    surgicalHistory.remove(at: index)
                                }
                            }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                            .frame(width: 40)
                            .disabled(surgicalHistory.count <= 1)
                        }
                    }
                }
                .padding(.horizontal)
            }
            .frame(height: 200)
            
            // Add new surgery row
            Button(action: {
                surgicalHistory.append(SurgicalHistory())
            }) {
                HStack {
                    Image(systemName: "plus.circle")
                    Text("Add Surgery")
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue.opacity(0.2))
                .cornerRadius(8)
            }
            
            // Optional: Assessment / Plans
            VStack(alignment: .leading, spacing: 8) {
                Text("Assessment / Plans")
                    .font(.headline)
                TextEditor(text: $assessmentPlans)
                    .frame(height: 100)
                    .padding(4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                    )
            }
            .padding(.top, 10)
        }
    }
    
    // A list of “common” conditions to show in the multi-select
    private var historyConditions: [String] {
        [
            "Hypertension", 
            "Diabetes", 
            "Cancer", 
            "Cholesterol", 
            "DVT/PE", 
            "HIV/AIDS", 
            "Kidney Disease",
            "Diverticulitis/Diverticulosis",
            "Stroke",
            "Heart Disease",
            "Depression",
            "Arthritis",
            "GERD",
            "Gout",
            "Other"  // We'll handle "Other" as a special case
        ]
    }
    
    // MARK: - Final Submission
    private func submitForm() {
        // Combine all values and perform submission
        print("Height: \(selectedHeight), Weight: \(selectedWeight)")
        print("Chief Complaint: \(chiefComplaint)")
        print("Pain Level: \(Int(painLevel))")
        print("Allergies: \(allergies)")
        print("Recent Hospitalizations: \(hospitalizations)")
        print("Recent Illness: \(recentIllnessSelection)")
        
        // Print medications
        for med in medications {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .short
            let startDateStr = dateFormatter.string(from: med.startDate)
            print("Medication: \(med.name), Dosage: \(med.dosage), Frequency: \(med.frequency), Start Date: \(startDateStr)")
        }
        
        // Print medical/family history
        print("Self Medical History: \(selfMedicalHistory)")
        print("Family Medical History: \(familyMedicalHistory)")
        
        // Print or store the surgical history
        for surgeryItem in surgicalHistory {
            print("Surgery: \(surgeryItem.surgery), Reason: \(surgeryItem.reason), Year: \(surgeryItem.year), Hospital: \(surgeryItem.hospital)")
        }
        
        print("Assessment / Plans: \(assessmentPlans)")
        
        // Save vitals data to patient model if needed - FIXED ASSIGNMENT SYNTAX
        patientModel.height = selectedHeight
        patientModel.weight = selectedWeight
        patientModel.temperature = temperature
        patientModel.heartRate = Int(heartRate)
        patientModel.painLevel = Int(painLevel)
        
        // Format medications as an array of dictionaries
        let medicationsData = medications.map { med -> [String: Any] in
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .short
            let startDateStr = dateFormatter.string(from: med.startDate)
            
            return [
                "name": med.name,
                "dosage": med.dosage,
                "frequency": med.frequency,
                "startDate": startDateStr
            ]
        }
        
        // Format surgical history as an array of dictionaries
        let surgicalHistoryData = surgicalHistory.map { surgery -> [String: String] in
            return [
                "surgery": surgery.surgery,
                "reason": surgery.reason,
                "year": surgery.year,
                "hospital": surgery.hospital
            ]
        }
        
        // Create a dictionary of all vital measurements to store in Firestore
        let vitalsData: [String: Any] = [
            // Basic vitals
            "height": selectedHeight,
            "weight": selectedWeight,
            "temperature": temperature,
            "respiratoryRate": Int(respiratoryRate),
            "bloodPressure": Int(bloodPressure),
            "spo2": Int(spo2),
            "heartRate": Int(heartRate),
            "glucose": Int(glucose),
            "painLevel": Int(painLevel),
            
            // Travel and illness
            "recentTravel": recentTravel,
            "recentIllness": recentIllnessSelection,
            "chiefComplaint": patientModel.reasonForVisit,
            
            // Medical history
            "selfMedicalHistory": selfMedicalHistory,
            "familyMedicalHistory": familyMedicalHistory,
            
            // Allergies and hospitalizations
            "allergies": allergies,
            "hasAllergies": !noAllergies,
            "hospitalizations": hospitalizations,
            "hasHospitalizations": !noHospitalizations,
            
            // Assessment plans
            "assessmentPlans": assessmentPlans,
            
            // Add medications and surgical history as organized submaps
            "medications": medicationsData,
            "surgicalHistory": surgicalHistoryData,
            
            // Add timestamp when vitals were recorded
            "recordedAt": Date().timeIntervalSince1970
        ]
        
        onComplete(vitalsData)
    }
}

struct MultiSelectSearchView: View {
    let title: String
    let allOptions: [String]
    @Binding var selectedOptions: [String]
    
    @State private var searchText: String = ""
    @State private var customOtherText: String = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Search field with Add button
            HStack {
                TextField(title, text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button(action: {
                    addCustomEntry()
                }) {
                    Text("Add")
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(5)
                }
                .disabled(searchText.isEmpty)
            }
            .padding(.bottom, 5)
            
            // Filtered list of matching options
            let filtered = allOptions.filter {
                searchText.isEmpty 
                || $0.lowercased().contains(searchText.lowercased())
            }
            
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(filtered, id: \.self) { option in
                        Button {
                            toggleOption(option)
                        } label: {
                            HStack {
                                Text(option)
                                Spacer()
                                if selectedOptions.contains(option) {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                            .padding(.vertical, 4)
                            .padding(.horizontal, 8)
                            .background(Color.white)
                        }
                        .foregroundColor(.primary)
                        .cornerRadius(8)
                    }
                }
            }
            .frame(maxHeight: 120) // Reduced height to make room for selections
            
            // If "Other" is in selected options, show a text field for custom entry
            if selectedOptions.contains("Other") {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Please specify 'Other':")
                        .font(.subheadline)
                    TextField("Enter custom condition", text: $customOtherText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onChange(of: customOtherText) { newValue in
                            updateCustomOther(newValue)
                        }
                }
            }
            
            // Display selected options with remove functionality
            VStack(alignment: .leading, spacing: 5) {
                Text("Selected Items:")
                    .font(.headline)
                    .padding(.top, 5)
                
                if selectedOptions.isEmpty {
                    Text("None selected")
                        .italic()
                        .foregroundColor(.gray)
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(selectedOptions, id: \.self) { option in
                                HStack(spacing: 4) {
                                    Text(option == "Other" ? (customOtherText.isEmpty ? "Other" : customOtherText) : option)
                                        .lineLimit(1)
                                    
                                    Button(action: {
                                        toggleOption(option)
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.red)
                                    }
                                    .buttonStyle(BorderlessButtonStyle())
                                }
                                .padding(.vertical, 4)
                                .padding(.horizontal, 8)
                                .background(
                                    Capsule()
                                        .fill(Color.blue.opacity(0.2))
                                )
                            }
                        }
                    }
                    .frame(height: 40)
                }
            }
            .padding(.vertical, 5)
            .padding(.horizontal, 8)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
        }
    }
    
    private func toggleOption(_ option: String) {
        if selectedOptions.contains(option) {
            // Deselect
            selectedOptions.removeAll { $0 == option }
            // If they deselect "Other", clear the custom text
            if option == "Other" {
                customOtherText = ""
            }
        } else {
            // Select
            selectedOptions.append(option)
        }
    }
    
    private func updateCustomOther(_ text: String) {
        // If user typed something for 'Other', you can store it
        // as a separate entry or override "Other" in the array.
        // For simplicity, we'll keep "Other" in selectedOptions,
        // and rely on `customOtherText` for the actual text.
    }
    
    private func addCustomEntry() {
        guard !searchText.isEmpty else { return }
        
        // Check if this entry already exists in our options
        if allOptions.contains(searchText) {
            // If it's a predefined option, just select it
            if !selectedOptions.contains(searchText) {
                selectedOptions.append(searchText)
            }
        } else {
            // Add as a custom entry directly
            selectedOptions.append(searchText)
        }
        
        // Clear the search field after adding
        searchText = ""
    }
}
