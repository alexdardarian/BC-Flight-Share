import SwiftUI

struct ProfileView: View {
    @Environment(AuthViewModel.self) private var authVM
    @State private var showSignOutAlert = false
    @State private var showEditProfile = false

    private var user: BCUser? { authVM.currentUser }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 16) {
                        Circle()
                            .fill(Color.bcMaroon)
                            .frame(width: 60, height: 60)
                            .overlay(
                                Text(user?.name.prefix(1).uppercased() ?? "?")
                                    .font(.title2.bold())
                                    .foregroundStyle(.white)
                            )
                        VStack(alignment: .leading, spacing: 4) {
                            Text(user?.name ?? "")
                                .font(.headline)
                            Text(user?.email ?? "")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }

                Section("My Info") {
                    LabeledContent("Gender", value: user?.gender ?? "—")
                    LabeledContent("Year", value: user?.grade ?? "—")
                    LabeledContent("Lives in", value: user?.dorm ?? "—")
                }

                Section("About") {
                    Label("Boston College", systemImage: "building.columns.fill")
                        .foregroundStyle(Color.bcMaroon)
                    Label("BC Flight Share v1.0", systemImage: "airplane")
                        .foregroundStyle(.primary)
                }

                Section {
                    Button(role: .destructive) {
                        showSignOutAlert = true
                    } label: {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }
            }
            .navigationTitle("Profile")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Edit") { showEditProfile = true }
                        .foregroundStyle(Color.bcMaroon)
                }
            }
            .sheet(isPresented: $showEditProfile) {
                if let user {
                    EditProfileView(user: user)
                        .environment(authVM)
                }
            }
            .alert("Sign Out", isPresented: $showSignOutAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Sign Out", role: .destructive) { authVM.signOut() }
            } message: {
                Text("Are you sure you want to sign out?")
            }
        }
    }
}
