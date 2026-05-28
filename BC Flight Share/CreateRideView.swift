import SwiftUI

struct CreateRideView: View {
    @Environment(RideViewModel.self) private var rideVM
    @Environment(AuthViewModel.self) private var authVM
    @Environment(\.dismiss) private var dismiss

    var selectedDate: Date?

    @State private var direction: RideDirection = .toAirport
    @State private var destination = ""
    @State private var terminal = ""
    @State private var meetingLocation = ""
    @State private var earliestDeparture: Date
    @State private var departureWindowMinutes = 30
    @State private var flightDepartureTime: Date
    @State private var maxRiders = 3
    @State private var notes = ""
    @State private var isSubmitting = false

    private let quickDestinations = [
        "Logan Airport (BOS)",
        "South Station",
        "Back Bay Station",
        "North Station",
        "TF Green Airport (PVD)",
        "Manchester Airport (MHT)",
        "JFK Airport (JFK)"
    ]

    private let quickMeetingSpots = [
        "Lower Campus Bus Stop",
        "Comm Ave Main Entrance",
        "Newton Campus",
        "Maloney Hall",
        "Stokes Hall",
        "O'Neill Library"
    ]

    private let bosTerminals = ["Terminal A", "Terminal B", "Terminal C", "Terminal E (Intl)"]

    init(selectedDate: Date? = nil) {
        self.selectedDate = selectedDate
        let base = selectedDate ?? Date()
        _earliestDeparture = State(initialValue: base)
        _flightDepartureTime = State(initialValue: base.addingTimeInterval(3600 * 2))
    }

    private var isValid: Bool {
        !destination.isEmpty && !meetingLocation.isEmpty && !terminal.isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                directionSection
                destinationSection
                terminalSection
                meetingLocationSection
                campusDepartureSection
                flightDepartureSection
                ridersSection
                notesSection
            }
            .navigationTitle("Post a Ride")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    postButton
                }
            }
        }
    }

    // MARK: - Sections

    private var directionSection: some View {
        Section {
            Picker("Direction", selection: $direction) {
                Text("✈ To Airport").tag(RideDirection.toAirport)
                Text("🏠 To BC").tag(RideDirection.toBC)
            }
            .pickerStyle(.segmented)
        }
    }

    private var destinationSection: some View {
        Section {
            chipRow(options: quickDestinations, selected: $destination, color: Color.bcMaroon)
            TextField("Or type a custom destination", text: $destination)
        } header: {
            Text("Destination")
        }
    }

    private var terminalSection: some View {
        Section {
            chipRow(options: bosTerminals, selected: $terminal, color: Color.bcMaroon)
            TextField("Or type a terminal (e.g. Terminal 4 at JFK)", text: $terminal)
        } header: {
            Text("Terminal")
        } footer: {
            Text(direction == .toAirport
                 ? "Which terminal will the Uber drop you off at?"
                 : "Which terminal does your flight arrive at?")
        }
    }

    private var meetingLocationSection: some View {
        Section {
            chipRow(options: quickMeetingSpots, selected: $meetingLocation, color: Color.bcGold)
            TextField("Or type a custom spot", text: $meetingLocation)
        } header: {
            Text(direction == .toAirport ? "Pickup at BC" : "Dropoff at BC")
        } footer: {
            Text("Use a public campus location. Do not enter a personal address.")
        }
    }

    private var campusDepartureSection: some View {
        Section {
            DatePicker(
                direction == .toAirport
                    ? "Earliest Departure from Campus"
                    : "Earliest Departure from Airport",
                selection: $earliestDeparture,
                in: Date()...
            )

            Picker("Window", selection: $departureWindowMinutes) {
                Text("30 min window").tag(30)
                Text("45 min window").tag(45)
                Text("1 hour window").tag(60)
            }

            HStack {
                Image(systemName: "clock.arrow.2.circlepath")
                    .foregroundStyle(Color.bcMaroon)
                Text(
                    (direction == .toAirport ? "Leaving campus: " : "Leaving airport: ")
                    + departureRangePreview
                )
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
        } header: {
            Text(direction == .toAirport ? "Departure from Campus" : "Departure from Airport")
        } footer: {
            Text(direction == .toAirport
                 ? "Riders can meet anytime within this window."
                 : "Riders will be picked up anytime within this window.")
        }
    }

    private var flightDepartureSection: some View {
        Section {
            DatePicker(
                direction == .toAirport ? "Flight Leaves At" : "Flight Arrives At",
                selection: $flightDepartureTime,
                displayedComponents: [.date, .hourAndMinute]
            )
        } header: {
            Text(direction == .toAirport ? "Flight Departure" : "Flight Arrival")
        } footer: {
            Text(direction == .toAirport
                 ? "The actual time your flight departs."
                 : "The actual time your flight lands.")
        }
    }

    private var ridersSection: some View {
        Section("Max Riders (including you)") {
            Stepper(value: $maxRiders, in: 2...5) {
                HStack {
                    Text("\(maxRiders) riders")
                    Spacer()
                    Text("Pool fits up to 5")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var notesSection: some View {
        Section("Notes (optional)") {
            TextField(
                "e.g., taking the 9am bus to the T first",
                text: $notes,
                axis: .vertical
            )
            .lineLimit(3...5)
        }
    }

    private var postButton: some View {
        Button {
            isSubmitting = true
            Task {
                let request = CreateRideRequest(
                    destination: destination,
                    terminal: terminal,
                    meetingLocation: meetingLocation,
                    earliestDepartureFromCampus: earliestDeparture,
                    departureWindowMinutes: departureWindowMinutes,
                    flightDepartureTime: flightDepartureTime,
                    maxRiders: maxRiders,
                    notes: notes,
                    direction: direction
                )
                await rideVM.createRide(request: request, user: authVM.currentUser!)
                dismiss()
            }
        } label: {
            if isSubmitting {
                ProgressView().tint(Color.bcMaroon)
            } else {
                Text("Post").bold()
                    .foregroundStyle(isValid ? Color.bcMaroon : .secondary)
            }
        }
        .disabled(!isValid || isSubmitting)
    }

    // MARK: - Helpers

    private var departureRangePreview: String {
        let end = earliestDeparture.addingTimeInterval(Double(departureWindowMinutes) * 60)
        let start = earliestDeparture.formatted(.dateTime.hour().minute())
        let endStr = end.formatted(.dateTime.hour().minute())
        return "\(start) – \(endStr)"
    }

    private func chipRow(options: [String], selected: Binding<String>, color: Color) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(options, id: \.self) { option in
                    Button { selected.wrappedValue = option } label: {
                        Text(option)
                            .font(.subheadline)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                selected.wrappedValue == option ? color : Color(.systemGray5)
                            )
                            .foregroundStyle(selected.wrappedValue == option ? .white : .primary)
                            .cornerRadius(20)
                    }
                }
            }
            .padding(.vertical, 4)
        }
        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 4, trailing: 0))
    }
}
