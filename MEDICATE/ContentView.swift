//
//  ContentView.swift
//  MEDICATE
//
//  Created by Alexander Eghoyan on 24/10/2023.
//


import SwiftUI
import UserNotifications
import SwiftUICharts

struct ContentView: View {
    init() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
            if success {
                print("All set!")
            } else if let error = error {
                print(error.localizedDescription)
            }
        }
    }

    @State private var history: [HistoryItem] = []

    @State var selection = 1
    @State var medications: [Medication] = [
        Medication(name: "Medicine A"),
        Medication(name: "Medicine B"),
        Medication(name: "Medicine C"),
        Medication(name: "Medicine D"),
        Medication(name: "Medicine E")
    ]
    @State private var untickedMedicationsCount = 0
    var body: some View {
        NavigationView {
            
            
            TabView(selection: $selection) {
                
                VStack {
                  
                        
                    Text("Alexander")
                        .font(.largeTitle)
                        .bold()
                        .offset(y:-140)
                    
                    HStack {
                 
                                        Image(systemName: "gear")
                            .font(.system(size: 50))
                                            .foregroundColor(.white)
                                            .offset(y:220)
                                           
                                    }
                                    .padding()
                    let totalMedications = history.count
                                      let takenMedications = history.filter { $0.isTaken }.count
                                      let outstandingMedications = totalMedications - takenMedications

                    MedicationRingChartView(takenPercentage: Double(takenMedications) / Double(totalMedications))
                                           .frame(width: 150, height: 150)
                                          .frame(width: 150, height: 150)
                                          .offset(y:-120)
                  
                    
                }
                
                    .tabItem {
                       
                     
                    }
                    .tag(1)

                ScheduleView(medications: $medications, history: $history)
                    .tabItem {
                        Text("Schedule")
                    }
                    .tag(2)

                HistoryView(history: $history, untickedMedicationsCount: $untickedMedicationsCount)
                    .tabItem {
                        Text("Record")
                    }
                    .tag(3)
            }
            .navigationTitle(selection == 1 ? "Welcome Back" : (selection == 2 ? "Schedule" : "History"))
            .tabViewStyle(.page)
            .indexViewStyle(.page(backgroundDisplayMode: .always))
            .padding()
            .preferredColorScheme(.dark)
        }
    }
}

struct MedicationRingChartView: View {
    var takenPercentage: Double
    
    var body: some View {
        PieChartView(
            data: [takenPercentage, 1 - takenPercentage], 
            title: "Medication Status",
            legend: "Consumption"
         
         
        )
        .frame(width: 250, height: 250)
    }
}













func addToHistory(history: Binding<[HistoryItem]>, name: String, time: Date) {
    history.wrappedValue.append(HistoryItem(name: name, time: time))
}

struct ScheduleView: View {
    @Binding var medications: [Medication]
    @State private var newMedicationName = ""
    @Binding var history: [HistoryItem]

    var body: some View {
        List {
            HStack {
                TextField("New Medication", text: $newMedicationName)
                Button(action: {
                    medications.append(Medication(name: newMedicationName))
                    newMedicationName = ""
                }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.gray)
                }
            }

            Section(header: Text("Medications")) {
                ForEach(medications.indices, id: \.self) { index in
                    MedicationRow(medication: $medications[index], medications: $medications, history: $history)
                }
            }
        }
        .navigationTitle("My Medication")
    }
}

struct Medication: Identifiable {
    let id = UUID()
    var name: String
    var selectedDate: Date
    var selectedTime: Date
    var selectedFrequency: String

    init(name: String) {
        self.name = name
        self.selectedDate = Date()
        self.selectedTime = Date()
        self.selectedFrequency = "Daily"
    }
}

struct MedicationRow: View {
    @Binding var medication: Medication
    @Binding var medications: [Medication]
    @Binding var history: [HistoryItem]

    var body: some View {
        NavigationLink(destination: MedicationDetailView(medication: $medication, medications: $medications, history: $history)) {
            Text(medication.name)
                .contextMenu {
                    Button(action: {
                        medications.removeAll(where: { medication in medication.id == self.medication.id })
                    }) {
                        Text("Delete")
                        Image(systemName: "trash")
                    }
                }
        }
    }
}

struct MedicationDetailView: View {
    @Binding var medication: Medication
    @Binding var medications: [Medication]
    @Binding var history: [HistoryItem]
    @Environment(\.presentationMode) var presentationMode
    let frequencyOptions = ["Daily", "Twice a Day", "Thrice a Day", "Alternate Days", "Weekly", "Monthly", "Custom"]

    var body: some View {
        VStack {
            Text("Select Starting Date")
                .font(.title)
                .bold()

            DatePicker("Starting Date", selection: $medication.selectedDate, displayedComponents: .date)
                .datePickerStyle(GraphicalDatePickerStyle())
                .padding()
                .accentColor(.gray)

            VStack {
                Text("Starting Time")
                    .offset(x: -50)

                DatePicker("", selection: $medication.selectedTime, displayedComponents: .hourAndMinute)
                    .datePickerStyle(GraphicalDatePickerStyle())
                    .accentColor(.blue)
                    .offset(y: -45)
                    .offset(x: -87)
            }

            Picker("Frequency", selection: $medication.selectedFrequency) {
                ForEach(frequencyOptions, id: \.self) { frequency in
                    Text(frequency)
                }
            }
            .pickerStyle(WheelPickerStyle())
            .padding()
            .offset(y: -10)

            Button(action: {
                presentationMode.wrappedValue.dismiss()

                let content = UNMutableNotificationContent()
                content.title = "Medication Reminder"
                content.sound = UNNotificationSound.default

                let calendar = Calendar.current
                var dateComponents = calendar.dateComponents([.year, .month, .day], from: medication.selectedDate)
                let timeComponents = calendar.dateComponents([.hour, .minute], from: medication.selectedTime)
                dateComponents.hour = timeComponents.hour
                dateComponents.minute = timeComponents.minute

                let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
                content.subtitle = "Time to take \(medication.name)"

                let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
                UNUserNotificationCenter.current().add(request)

                // Add to history log
                if let scheduledTime = trigger.nextTriggerDate() {
                    addToHistory(history: $history, name: medication.name, time: scheduledTime)
                }
            }) {
                Text("Schedule")
                    .foregroundColor(.blue)
            }
        }
    }
}

struct HistoryItem: Identifiable {
    let id = UUID()
    let name: String
    let time: Date
    var isTaken: Bool

    init(name: String, time: Date, isTaken: Bool = false) {
        self.name = name
        self.time = time
        self.isTaken = isTaken
    }
}

struct HistoryView: View {
    
    @Binding var history: [HistoryItem]
    @Binding var untickedMedicationsCount: Int
    var body: some View {
        List {
            ForEach(history, id: \.id) { item in
                HStack {
                    Image(systemName: item.isTaken ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(item.isTaken ? .green : .gray)
                        .onTapGesture {
                            toggleMedicationTaken(item)
                        }
                    Text(" \(item.name), Scheduled: \(formattedTime(item.time))")
                }
            }
        }
        .navigationTitle("History")
    }

    func formattedTime(_ time: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: time)
    }

    func toggleMedicationTaken(_ item: HistoryItem) {
            if let index = history.firstIndex(where: { $0.id == item.id }) {
                if !history[index].isTaken {
                    // Increase the count when unticking (grey)
                    untickedMedicationsCount += 1
                } else {
                    // Decrease the count when ticking (green)
                    untickedMedicationsCount -= 1
                }
                history[index].isTaken.toggle()
            }
        }
    }

   


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

