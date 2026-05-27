import Foundation
import FirebaseFirestore

@Observable
@MainActor
class ChatViewModel {
    var messages: [Message] = []

    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?

    func startListening(rideId: String) {
        let ref = db
            .collection("rides")
            .document(rideId)
            .collection("messages")
            .order(by: "createdAt")
        listener = ref.addSnapshotListener { [weak self] snapshot, _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.messages = (snapshot?.documents ?? []).compactMap {
                    try? $0.data(as: Message.self)
                }
            }
        }
    }

    func stopListening() {
        listener?.remove()
    }

    func sendMessage(text: String, user: BCUser, rideId: String) async {
        let msg = Message(
            senderId: user.id,
            senderName: user.name,
            text: text,
            createdAt: Date()
        )
        let ref = db
            .collection("rides")
            .document(rideId)
            .collection("messages")
        do {
            _ = try ref.addDocument(from: msg)
        } catch {}
    }
}
