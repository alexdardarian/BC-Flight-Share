import SwiftUI

struct HomeView: View {
    @Environment(AuthViewModel.self) private var authVM
    @State private var rideVM = RideViewModel()

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
        .onAppear { rideVM.startListening() }
        .onDisappear { rideVM.stopListening() }
    }
}
