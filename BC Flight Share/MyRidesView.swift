import SwiftUI

struct MyRidesView: View {
    @Environment(RideViewModel.self) private var rideVM
    @Environment(AuthViewModel.self) private var authVM

    private var myPostedRides: [Ride] {
        guard let user = authVM.currentUser else { return [] }
        return rideVM.rides
            .filter { $0.creatorId == user.id }
            .sorted { $0.earliestDepartureFromCampus < $1.earliestDepartureFromCampus }
    }

    private var myJoinedRides: [Ride] {
        guard let user = authVM.currentUser else { return [] }
        return rideVM.rides
            .filter { $0.riders[user.id] != nil && $0.creatorId != user.id }
            .sorted { $0.earliestDepartureFromCampus < $1.earliestDepartureFromCampus }
    }

    private var hasAnyRides: Bool {
        !myPostedRides.isEmpty || !myJoinedRides.isEmpty
    }

    var body: some View {
        NavigationStack {
            Group {
                if hasAnyRides {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 24) {
                            if !myPostedRides.isEmpty {
                                rideSection(title: "My Posted Rides", rides: myPostedRides)
                            }
                            if !myJoinedRides.isEmpty {
                                rideSection(title: "My Joined Rides", rides: myJoinedRides)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                } else {
                    VStack(spacing: 16) {
                        Spacer()
                        Image(systemName: "airplane.circle")
                            .font(.system(size: 60))
                            .foregroundStyle(Color.secondary.opacity(0.3))
                        Text("No upcoming rides")
                            .font(.title3.bold())
                            .foregroundStyle(.secondary)
                        Text("Head to the calendar to post or join a ride")
                            .font(.subheadline)
                            .foregroundStyle(Color.secondary.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        Spacer()
                    }
                }
            }
            .navigationTitle("My Rides")
        }
    }

    private func rideSection(title: String, rides: [Ride]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
                .foregroundStyle(Color.bcMaroon)
                .padding(.leading, 4)
            ForEach(rides) { ride in
                NavigationLink(destination: RideDetailView(ride: ride)) {
                    RideCard(ride: ride)
                }
                .buttonStyle(.plain)
            }
        }
    }
}
