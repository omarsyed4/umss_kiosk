import SwiftUI

struct VitalsStepView: View {
    let onComplete: () -> Void

    @ObservedObject var patientModel: PatientModel
    // Current slide index (0...4)
    @State private var currentSlide: Int = 0

    // Slide 1: Height and Weight pickers
    @State private var selectedHeight: Int = 170
    @State private var selectedWeight: Int = 70
    let heights = Array(100...250)
    let weights = Array(30...150)

    // Add new state properties for the sliding number bars
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

    var body: some View {
        VStack {
            Spacer()

            // Display the current slide based on the currentSlide index
            Group {
                if currentSlide == 0 {
                    // Slide 1: Height and Weight
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
                } else if currentSlide == 1 {
                    // Slide 2: Chief Complaint
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
                } else if currentSlide == 2 {
                    // Slide 3: Pain Indicator + Recent Travel/Illness
                    VStack(spacing: 20) {
                        Text("Pain Indicator")
                            .font(.title2)
                            .fontWeight(.semibold)

                        Slider(value: $painLevel, in: 1...10, step: 1)
                        Text("Pain Level: \(Int(painLevel))")
                            .font(.headline)

                        // New questions using ChoiceRow
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
                            title: "A Fever",
                            isSelected: recentIllnessSelection == "A Fever",
                            action: { recentIllnessSelection = "A Fever" }
                        )
                        ChoiceRow(
                            title: "B Cough",
                            isSelected: recentIllnessSelection == "B Cough",
                            action: { recentIllnessSelection = "B Cough" }
                        )
                        ChoiceRow(
                            title: "C Congestion",
                            isSelected: recentIllnessSelection == "C Congestion",
                            action: { recentIllnessSelection = "C Congestion" }
                        )
                        ChoiceRow(
                            title: "D None",
                            isSelected: recentIllnessSelection == "D None",
                            action: { recentIllnessSelection = "D None" }
                        )
                    }
                } else if currentSlide == 3 {
                    // Slide 4: Allergies
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
                } else if currentSlide == 4 {
                    // Slide 5: Recent Hospitalizations
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
            }
            .padding()
            .animation(.easeInOut, value: currentSlide)
            
            Spacer()
            
            // Navigation buttons at the bottom
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
                
                if currentSlide < 4 {
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
    
    // Called when the user taps the final Submit button.
    private func submitForm() {
        // Combine all values and perform submission (replace this with your real logic)
        print("Height: \(selectedHeight), Weight: \(selectedWeight)")
        print("Chief Complaint: \(chiefComplaint)")
        print("Pain Level: \(Int(painLevel))")
        print("Allergies: \(allergies)")
        print("Recent Hospitalizations: \(hospitalizations)")
        print("Recent Illness: \(recentIllnessSelection)")
        // TODO: Add form submission logic (e.g., send data to backend)
    }
}

struct VitalsStepView_Previews: PreviewProvider {
    static var previews: some View {
        VitalsStepView(onComplete: {}, patientModel: PatientModel())
    }
}
