import SwiftUI
import UIKit
import FirebaseFirestore

struct RideDetailView: View {
    @Environment(RideViewModel.self) private var rideVM
    @Environment(AuthViewModel.self) private var authVM
    @Environment(BlockViewModel.self) private var blockVM
    @Environment(\.dismiss) private var dismiss
    let ride: Ride

    @State private var userToBlock: (id: String, name: String)?

    private var currentUser: BCUser? { authVM.currentUser }
    private var isJoined: Bool { currentUser.map { ride.riders[$0.id] != nil } ?? false }
    private var isCreator: Bool { currentUser?.id == ride.creatorId }
    private var canDelete: Bool {
        ride.earliestDepartureFromCampus.timeIntervalSince(Date()) > 24 * 3600
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                banner
                    .ignoresSafeArea(edges: .top)

                VStack(alignment: .leading, spacing: 20) {
                    flightInfoRows
                    Divider()
                    ridersRow
                    if !ride.notes.isEmpty {
                        Divider()
                        DetailRow(icon: "note.text", iconColor: .secondary, title: "Notes") {
                            Text(ride.notes)
                        }
                    }
                    Divider()
                    groupChatRow
                    Divider()
                    uberButton
                    liabilityNote
                    actionButton
                }
                .padding(24)
            }
        }
        .navigationTitle("Ride Details")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Block User", isPresented: Binding(
            get: { userToBlock != nil },
            set: { if !$0 { userToBlock = nil } }
        )) {
            Button("Cancel", role: .cancel) { userToBlock = nil }
            Button("Block", role: .destructive) {
                if let target = userToBlock, let me = currentUser {
                    Task { await blockVM.blockUser(myId: me.id, userId: target.id) }
                }
                userToBlock = nil
            }
        } message: {
            if let target = userToBlock {
                Text("Block \(target.name)? Their rides won't appear in your feed.")
            }
        }
    }

    // MARK: - Subviews

    private var banner: some View {
        let icon = ride.rideDirection == .toAirport ? "airplane.departure" : "airplane.arrival"
        let deptLabel = ride.rideDirection == .toAirport ? "Leaving campus: " : "Leaving airport: "
        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon).font(.title3)
                Text(ride.destination).font(.title2.bold())
            }
            .foregroundStyle(.white)

            Text(ride.earliestDepartureFromCampus.formatted(.dateTime.weekday(.wide).month(.wide).day()))
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.85))

            HStack(spacing: 4) {
                Image(systemName: "clock")
                Text(deptLabel + ride.departureRangeString)
            }
            .font(.subheadline)
            .foregroundStyle(.white.opacity(0.85))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(24)
        .background(Color.bcMaroon)
    }

    private var flightInfoRows: some View {
        let flightTitle = ride.rideDirection == .toAirport ? "Flight Departs" : "Flight Arrives"
        let meetTitle = ride.rideDirection == .toAirport ? "Pickup at BC" : "Dropoff at BC"
        return VStack(alignment: .leading, spacing: 16) {
            DetailRow(icon: "airplane", iconColor: Color.bcMaroon, title: flightTitle) {
                Text(ride.flightDepartureTime.formatted(
                    .dateTime.weekday(.abbreviated).month(.abbreviated).day().hour().minute()
                ))
            }
            Divider()
            DetailRow(icon: "door.right.hand.open", iconColor: Color.bcMaroon, title: "Terminal") {
                Text(ride.terminal).font(.body.bold())
            }
            Divider()
            DetailRow(icon: "mappin.circle.fill", iconColor: Color.bcGold, title: meetTitle) {
                Text(ride.meetingLocation)
            }
        }
    }

    private var ridersRow: some View {
        let riderTitle = "Riders (\(ride.riders.count)/\(ride.maxRiders))"
        return DetailRow(icon: "person.2.fill", iconColor: Color.bcMaroon, title: riderTitle) {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(ride.riders).sorted(by: { $0.value.name < $1.value.name }), id: \.key) { uid, rider in
                    riderRow(uid: uid, name: rider.name, gender: rider.gender)
                        .contextMenu {
                            if uid != currentUser?.id {
                                Button(role: .destructive) {
                                    userToBlock = (id: uid, name: rider.name)
                                } label: {
                                    Label("Block User", systemImage: "hand.raised.fill")
                                }
                            }
                        }
                }
                ForEach(0..<ride.spotsLeft, id: \.self) { _ in
                    emptySpotRow
                }
            }
        }
    }

    private var groupChatRow: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Group Chat", systemImage: "bubble.left.and.bubble.right.fill")
                .font(.subheadline.bold())
                .foregroundStyle(.secondary)

            if isCreator || isJoined {
                NavigationLink(destination: ChatView(ride: ride)) {
                    HStack {
                        Image(systemName: "bubble.left.and.bubble.right.fill")
                        Text("Open Group Chat")
                        Spacer()
                        Image(systemName: "chevron.right").font(.caption)
                    }
                    .font(.headline)
                    .padding()
                    .background(Color.bcMaroon.opacity(0.1))
                    .foregroundStyle(Color.bcMaroon)
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)
            } else {
                Text("Join the ride to access the group chat.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var uberButton: some View {
        Button { openUber() } label: {
            HStack {
                Image(systemName: "car.fill")
                Text("Open in Uber")
                Spacer()
                Image(systemName: "arrow.up.right").font(.caption)
            }
            .font(.headline)
            .padding()
            .background(Color.black)
            .foregroundStyle(.white)
            .cornerRadius(12)
        }
    }

    @ViewBuilder
    private var actionButton: some View {
        if isCreator {
            if canDelete {
                Button(role: .destructive) {
                    Task {
                        await rideVM.deleteRide(ride)
                        dismiss()
                    }
                } label: {
                    styledButton("Delete Ride", background: Color.red.opacity(0.1), foreground: .red)
                }
            } else {
                VStack(spacing: 6) {
                    styledButton("Delete Ride", background: Color(.systemGray5), foreground: .secondary)
                    Text("Cannot delete within 24 hours of departure")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
        } else if isJoined {
            Button {
                guard let user = currentUser else { return }
                Task {
                    await rideVM.leaveRide(ride, user: user)
                    dismiss()
                }
            } label: {
                styledButton("Leave Ride", background: Color(.systemGray5), foreground: .red)
            }
        } else {
            Button {
                guard let user = currentUser else { return }
                Task {
                    await rideVM.joinRide(ride, user: user)
                    dismiss()
                }
            } label: {
                styledButton(
                    ride.isFull ? "Ride is Full" : "Join Ride",
                    background: ride.isFull ? Color(.systemGray4) : Color.bcMaroon,
                    foreground: .white
                )
            }
            .disabled(ride.isFull)
        }
    }

    // MARK: - Helpers

    private func riderRow(uid: String, name: String, gender: String) -> some View {
        let showFull = isJoined || isCreator
        let displayName = showFull ? name : abbreviatedName(name)
        let displayText = showFull && !gender.isEmpty ? "\(displayName) (\(gender))" : displayName
        return HStack(spacing: 10) {
            Circle()
                .fill(Color.bcMaroon.opacity(0.12))
                .frame(width: 32, height: 32)
                .overlay(
                    Text(String(name.prefix(1)).uppercased())
                        .font(.subheadline.bold())
                        .foregroundStyle(Color.bcMaroon)
                )
            Text(displayText)
                .font(.subheadline)
        }
    }

    private func abbreviatedName(_ fullName: String) -> String {
        let parts = fullName.split(separator: " ").map(String.init)
        guard parts.count >= 2 else { return fullName }
        return "\(parts[0]) \(parts[1].prefix(1))."
    }

    private var emptySpotRow: some View {
        HStack(spacing: 10) {
            Circle()
                .strokeBorder(
                    Color.secondary.opacity(0.3),
                    style: StrokeStyle(lineWidth: 1.5, dash: [4])
                )
                .frame(width: 32, height: 32)
            Text("Open spot").font(.subheadline).foregroundStyle(.secondary)
        }
    }

    private func styledButton(_ title: String, background: Color, foreground: Color) -> some View {
        Text(title)
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding()
            .background(background)
            .foregroundStyle(foreground)
            .cornerRadius(12)
    }

    @ViewBuilder
    private var liabilityNote: some View {
        if !isCreator && !isJoined {
            Text("Meet in a public campus location. BC Flight Share is not responsible for ride safety.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 4)
        }
    }

    private func openUber() {
        let uberURL = URL(string: "uber://")!
        let fallback = URL(string: "https://m.uber.com/")!
        if UIApplication.shared.canOpenURL(uberURL) {
            UIApplication.shared.open(uberURL)
        } else {
            UIApplication.shared.open(fallback)
        }
    }
}

struct DetailRow<Content: View>: View {
    let icon: String
    let iconColor: Color
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon).foregroundStyle(iconColor)
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundStyle(.secondary)
            }
            content()
                .padding(.leading, 26)
        }
    }
}
