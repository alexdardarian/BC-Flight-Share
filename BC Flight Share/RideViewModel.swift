import Foundation
import FirebaseFirestore

@Observable
@MainActor
class RideViewModel {
    var rides: [Ride] = []
    var isLoading = false
    var errorMessage: String?

    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?

    func startListening() {
        isLoading = true
        listener = db.collection("rides")
            .order(by: "earliestDepartureFromCampus")
            .addSnapshotListener { [weak self] snapshot, error in
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    self.isLoading = false
                    if let error {
                        self.errorMessage = error.localizedDescription
                        return
                    }
                    let all = (snapshot?.documents ?? []).compactMap {
                        try? $0.data(as: Ride.self)
                    }
                    self.rides = all.filter { !$0.isExpired }
                }
            }
    }

    func stopListening() {
        listener?.remove()
    }

    func ridesOn(date: Date, excluding blockedIds: Set<String> = []) -> [Ride] {
        let key = dateKey(for: date)
        return rides.filter { $0.dateKey == key && !blockedIds.contains($0.creatorId) }
    }

    func hasRides(on date: Date, excluding blockedIds: Set<String> = []) -> Bool {
        !ridesOn(date: date, excluding: blockedIds).isEmpty
    }

    func createRide(request: CreateRideRequest, user: BCUser) async {
        let ride = Ride(
            creatorId: user.id,
            creatorName: user.name,
            destination: request.destination,
            terminal: request.terminal,
            meetingLocation: request.meetingLocation,
            earliestDepartureFromCampus: request.earliestDepartureFromCampus,
            departureWindowMinutes: request.departureWindowMinutes,
            flightDepartureTime: request.flightDepartureTime,
            maxRiders: request.maxRiders,
            riders: [user.id: RiderInfo(name: user.name, gender: user.gender)],
            notes: request.notes,
            createdAt: Date(),
            direction: request.direction
        )
        do {
            _ = try db.collection("rides").addDocument(from: ride)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func joinRide(_ ride: Ride, user: BCUser) async {
        guard let id = ride.id,
              ride.riders[user.id] == nil,
              !ride.isFull else { return }
        do {
            try await db.collection("rides").document(id).updateData([
                "riders.\(user.id)": ["name": user.name, "gender": user.gender]
            ])
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func leaveRide(_ ride: Ride, user: BCUser) async {
        guard let id = ride.id, ride.creatorId != user.id else { return }
        do {
            try await db.collection("rides").document(id).updateData([
                "riders.\(user.id)": FieldValue.delete()
            ])
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteRide(_ ride: Ride) async {
        guard let id = ride.id else { return }
        do {
            try await db.collection("rides").document(id).delete()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func dateKey(for date: Date) -> String {
        let comps = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return "\(comps.year ?? 0)-\(comps.month ?? 0)-\(comps.day ?? 0)"
    }
}
