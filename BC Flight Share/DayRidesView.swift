import SwiftUI

struct DayRidesView: View {
    @Environment(RideViewModel.self) private var rideVM
    @Environment(AuthViewModel.self) private var authVM
    @Environment(BlockViewModel.self) private var blockVM
    let date: Date
    @State private var showCreateRide = false

    private var rides: [Ride] { rideVM.ridesOn(date: date, excluding: blockVM.blockedUserIds) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(date.formatted(.dateTime.weekday(.wide).month(.wide).day()))
                    .font(.headline)
                Spacer()
                Button {
                    showCreateRide = true
                } label: {
                    Label("Post Ride", systemImage: "plus")
                        .font(.subheadline.bold())
                        .foregroundStyle(Color.bcMaroon)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 8)

            if rides.isEmpty {
                VStack(spacing: 10) {
                    Spacer()
                    Text("No rides posted for this day")
                        .foregroundStyle(.secondary)
                    Button {
                        showCreateRide = true
                    } label: {
                        Text("Be the first to post one")
                            .font(.subheadline.bold())
                            .foregroundStyle(Color.bcMaroon)
                    }
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(rides) { ride in
                            NavigationLink(destination: RideDetailView(ride: ride)) {
                                RideCard(ride: ride)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }
            }
        }
        .sheet(isPresented: $showCreateRide) {
            CreateRideView(selectedDate: date)
                .environment(rideVM)
                .environment(authVM)
        }
    }
}

struct RideCard: View {
    let ride: Ride

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(
                    systemName: ride.rideDirection == .toAirport
                        ? "airplane.departure"
                        : "airplane.arrival"
                )
                .foregroundStyle(Color.bcMaroon)
                Text(ride.destination)
                    .font(.headline)
                    .lineLimit(1)
                Text(ride.rideDirection == .toAirport ? "To Airport" : "To BC")
                    .font(.caption.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        (ride.rideDirection == .toAirport ? Color.bcMaroon : Color.bcGold).opacity(0.12)
                    )
                    .foregroundStyle(ride.rideDirection == .toAirport ? Color.bcMaroon : Color.bcGold)
                    .cornerRadius(6)
                Spacer()
                Text(ride.departureRangeString)
                    .font(.caption.bold())
                    .foregroundStyle(Color.bcMaroon)
            }

            HStack(spacing: 6) {
                Image(systemName: "airplane.circle.fill")
                    .foregroundStyle(Color.bcMaroon)
                    .font(.caption)
                Text("Terminal: \(ride.terminal)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 6) {
                Image(systemName: "mappin.circle.fill")
                    .foregroundStyle(Color.bcGold)
                Text(
                    (ride.rideDirection == .toAirport ? "Pickup: " : "Dropoff: ")
                    + ride.meetingLocation
                )
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }

            HStack {
                Image(systemName: "person.2.fill")
                    .foregroundStyle(.secondary)
                    .font(.caption)
                Text("\(ride.riders.count)/\(ride.maxRiders) riders")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                if ride.isFull {
                    badge("Full", color: .red)
                } else {
                    badge("\(ride.spotsLeft) spot\(ride.spotsLeft == 1 ? "" : "s") left", color: .green)
                }
            }

            Text("Posted by \(ride.creatorName)")
                .font(.caption)
                .foregroundStyle(Color.secondary.opacity(0.7))
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
    }

    private func badge(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.caption.bold())
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.12))
            .foregroundStyle(color)
            .cornerRadius(6)
    }
}
