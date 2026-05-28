import SwiftUI

struct ChatView: View {
    @Environment(AuthViewModel.self) private var authVM
    @Environment(BlockViewModel.self) private var blockVM
    @State private var chatVM = ChatViewModel()
    @State private var messageText = ""
    @State private var pendingFlagMessage: Message?
    @State private var pendingBlockUser: (id: String, name: String)?

    let ride: Ride

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(chatVM.messages) { message in
                            let isOwn = message.senderId == authVM.currentUser?.id
                            MessageBubble(message: message, isOwn: isOwn)
                                .id(message.id)
                                .contextMenu {
                                    if !isOwn {
                                        Button {
                                            pendingFlagMessage = message
                                        } label: {
                                            Label("Flag Message", systemImage: "flag.fill")
                                        }
                                        Button(role: .destructive) {
                                            pendingBlockUser = (id: message.senderId, name: message.senderName)
                                        } label: {
                                            Label("Block User", systemImage: "hand.raised.fill")
                                        }
                                    }
                                }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                }
                .onChange(of: chatVM.messages.count) { _, _ in
                    if let lastId = chatVM.messages.last?.id {
                        withAnimation { proxy.scrollTo(lastId, anchor: .bottom) }
                    }
                }
            }

            Divider()

            HStack(spacing: 12) {
                TextField("Message...", text: $messageText, axis: .vertical)
                    .lineLimit(1...4)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6))
                    .cornerRadius(20)

                Button { send() } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundStyle(
                            messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                ? Color.secondary
                                : Color.bcMaroon
                        )
                }
                .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .navigationTitle(ride.destination)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            guard let rideId = ride.id else { return }
            chatVM.startListening(rideId: rideId)
        }
        .onDisappear { chatVM.stopListening() }
        .alert("Flag Message", isPresented: Binding(
            get: { pendingFlagMessage != nil },
            set: { if !$0 { pendingFlagMessage = nil } }
        )) {
            Button("Cancel", role: .cancel) { pendingFlagMessage = nil }
            Button("Report", role: .destructive) {
                if let msg = pendingFlagMessage,
                   let msgId = msg.id,
                   let me = authVM.currentUser,
                   let rideId = ride.id {
                    Task {
                        await blockVM.reportMessage(
                            reporterId: me.id,
                            reportedUserId: msg.senderId,
                            messageId: msgId,
                            rideId: rideId
                        )
                    }
                }
                pendingFlagMessage = nil
            }
        } message: {
            Text("Report this message to BC Flight Share moderators?")
        }
        .alert("Block User", isPresented: Binding(
            get: { pendingBlockUser != nil },
            set: { if !$0 { pendingBlockUser = nil } }
        )) {
            Button("Cancel", role: .cancel) { pendingBlockUser = nil }
            Button("Block", role: .destructive) {
                if let target = pendingBlockUser, let me = authVM.currentUser {
                    Task { await blockVM.blockUser(myId: me.id, userId: target.id) }
                }
                pendingBlockUser = nil
            }
        } message: {
            if let target = pendingBlockUser {
                Text("Block \(target.name)? Their rides won't appear in your feed.")
            }
        }
    }

    private func send() {
        let trimmed = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              let user = authVM.currentUser,
              let rideId = ride.id else { return }
        messageText = ""
        Task { await chatVM.sendMessage(text: trimmed, user: user, rideId: rideId) }
    }
}

struct MessageBubble: View {
    let message: Message
    let isOwn: Bool

    var body: some View {
        VStack(alignment: isOwn ? .trailing : .leading, spacing: 3) {
            if !isOwn {
                Text(message.senderName)
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                    .padding(.leading, 4)
            }
            Text(message.text)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(isOwn ? Color.bcMaroon : Color(.systemGray5))
                .foregroundStyle(isOwn ? .white : .primary)
                .cornerRadius(16)
        }
        .frame(maxWidth: .infinity, alignment: isOwn ? .trailing : .leading)
    }
}
