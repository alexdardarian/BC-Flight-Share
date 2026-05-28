import SwiftUI

struct HomeView: View {
    @Environment(AuthViewModel.self) private var authVM
    @State private var rideVM = RideViewModel()
    @State private var blockVM = BlockViewModel()

    var body: some View {
        TabView {
            CalendarTabView()
                .tabItem { Label("Flights", systemImage: "calendar") }

            MyRidesView()
                .tabItem { Label("My Rides", systemImage: "person.2.fill") }

            ChatsView()
                .tabItem { Label("Chats", systemImage: "bubble.left.and.bubble.right.fill") }

            ProfileView()
                .tabItem { Label("Profile", systemImage: "person.circle") }
        }
        .tint(Color.bcMaroon)
        .environment(rideVM)
        .environment(blockVM)
        .alert("Error", isPresented: .init(
            get: { rideVM.errorMessage != nil },
            set: { if !$0 { rideVM.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { rideVM.errorMessage = nil }
        } message: {
            Text(rideVM.errorMessage ?? "")
        }
        .onAppear {
            rideVM.startListening()
            if let uid = authVM.currentUser?.id {
                blockVM.startListening(userId: uid)
            }
        }
        .onChange(of: authVM.currentUser?.id) { _, newId in
            if let uid = newId, blockVM.blockedUserIds.isEmpty {
                blockVM.startListening(userId: uid)
            }
        }
        .onDisappear {
            rideVM.stopListening()
            blockVM.stopListening()
        }
    }
}
