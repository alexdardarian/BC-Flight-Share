import Foundation
import SwiftUI
import FirebaseAuth
import FirebaseFirestore

@Observable
@MainActor
class AuthViewModel {
    var currentUser: BCUser?
    var isLoading = true
    var errorMessage: String?

    private let db = Firestore.firestore()
    private var authListener: AuthStateDidChangeListenerHandle?

    init() {
        authListener = Auth.auth().addStateDidChangeListener { [weak self] _, firebaseUser in
            Task { @MainActor [weak self] in
                guard let self else { return }
                if let firebaseUser {
                    await self.fetchUser(uid: firebaseUser.uid)
                } else {
                    self.currentUser = nil
                    self.isLoading = false
                }
            }
        }

        // Fallback: if Firebase never responds within 5 seconds, show auth screen
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(5))
            if self.isLoading {
                self.isLoading = false
            }
        }
    }

    func signUp(
        name: String,
        email: String,
        password: String,
        gender: String,
        grade: String,
        dorm: String
    ) async {
        errorMessage = nil
        guard email.lowercased().hasSuffix("@bc.edu") else {
            errorMessage = "Please use your @bc.edu email address."
            return
        }
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "Please enter your name."
            return
        }
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            let user = BCUser(
                id: result.user.uid,
                name: name,
                email: email,
                gender: gender,
                grade: grade,
                dorm: dorm,
                createdAt: Date()
            )
            try db.collection("users").document(user.id).setData(from: user)
            currentUser = user
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func signIn(email: String, password: String) async {
        errorMessage = nil
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            await fetchUser(uid: result.user.uid)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func updateProfile(name: String, gender: String, grade: String, dorm: String) async {
        guard var user = currentUser else { return }
        errorMessage = nil
        user.name = name
        user.gender = gender
        user.grade = grade
        user.dorm = dorm
        do {
            try db.collection("users").document(user.id).setData(from: user)
            currentUser = user
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func signOut() {
        try? Auth.auth().signOut()
        currentUser = nil
    }

    private func fetchUser(uid: String) async {
        do {
            let doc = try await db.collection("users").document(uid).getDocument()
            currentUser = try doc.data(as: BCUser.self)
        } catch {
            currentUser = nil
        }
        isLoading = false
    }
}
