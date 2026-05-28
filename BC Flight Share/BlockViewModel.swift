import Foundation
import FirebaseFirestore

@Observable
@MainActor
class BlockViewModel {
    var blockedUserIds: Set<String> = []
    var errorMessage: String?

    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?

    func startListening(userId: String) {
        listener = db
            .collection("users")
            .document(userId)
            .collection("blocks")
            .addSnapshotListener { [weak self] snapshot, _ in
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    self.blockedUserIds = Set((snapshot?.documents ?? []).map { $0.documentID })
                }
            }
    }

    func stopListening() {
        listener?.remove()
        listener = nil
    }

    func blockUser(myId: String, userId: String) async {
        do {
            try await db
                .collection("users")
                .document(myId)
                .collection("blocks")
                .document(userId)
                .setData(["blockedAt": FieldValue.serverTimestamp()])
        } catch {
            errorMessage = "Failed to block user. Please try again."
        }
    }

    func reportMessage(reporterId: String, reportedUserId: String, messageId: String, rideId: String) async {
        let data: [String: Any] = [
            "reporterId": reporterId,
            "reportedUserId": reportedUserId,
            "messageId": messageId,
            "rideId": rideId,
            "createdAt": FieldValue.serverTimestamp()
        ]
        do {
            _ = try await db.collection("reports").addDocument(data: data)
        } catch {
            errorMessage = "Failed to submit report. Please try again."
        }
    }
}
