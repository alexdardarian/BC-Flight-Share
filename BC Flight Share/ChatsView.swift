import SwiftUI

struct ChatsView: View {
    @Environment(RideViewModel.self) private var rideVM
    @Environment(AuthViewModel.self) private var authVM

    private var myRides: [Ride] {
        guard let user = authVM.currentUser else { return [] }
        return rideVM.rides
            .filter { $0.riders[user.id] != nil }
            .sorted { $0.earliestDepartureFromCampus < $1.earliestDepartureFromCampus }
    }

    var body: some View {
        NavigationStack {
            Group {
                if myRides.isEmpty {
                    VStack(spacing: 16) {
                        Spacer()
                        Image(systemName: "bubble.left.and.bubble.right")
                            .font(.system(size: 60))
                            .foregroundStyle(Color.secondary.opacity(0.3))
                        Text("No chats yet")
                            .font(.title3.bold())
                            .foregroundStyle(.secondary)
                        Text("Join or post a ride to start chatting with your group")
                            .font(.subheadline)
                            .foregroundStyle(Color.secondary.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        Spacer()
                    }
                } else {
                    List {
                        ForEach(myRides) { ride in
                            NavigationLink(destination: ChatView(ride: ride)) {
                                ChatRideRow(ride: ride)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Chats")
        }
    }
}

struct ChatRideRow: View {
    let ride: Ride

    var body: some View {
        HStack(spacing: 14) {
            Circle()
                .fill(Color.bcMaroon.opacity(0.12))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: "airplane.departure")
                        .foregroundStyle(Color.bcMaroon)
                        .font(.system(size: 18))
                )

            VStack(alignment: .leading, spacing: 3) {
                Text(ride.destination)
                    .font(.headline)
                    .lineLimit(1)
                Text(
                    ride.earliestDepartureFromCampus
                        .formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day())
                )
                .font(.subheadline)
                .foregroundStyle(.secondary)
                Text("\(ride.riders.count) rider\(ride.riders.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
