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
    var pendingVerification = false
    var pendingVerificationEmail = ""

    private static let devWhitelist: Set<String> = ["alexdardarian@gmail.com"]
    private let db = Firestore.firestore()
    private var authListener: AuthStateDidChangeListenerHandle?

    init() {
        authListener = Auth.auth().addStateDidChangeListener { [weak self] _, firebaseUser in
            Task { @MainActor [weak self] in
                guard let self else { return }
                if let firebaseUser {
                    if firebaseUser.isEmailVerified {
                        self.pendingVerification = false
                        self.pendingVerificationEmail = ""
                        await self.fetchUser(uid: firebaseUser.uid)
                    } else {
                        self.pendingVerification = true
                        self.pendingVerificationEmail = firebaseUser.email ?? ""
                        self.currentUser = nil
                        self.isLoading = false
                    }
                } else {
                    self.currentUser = nil
                    self.pendingVerification = false
                    self.pendingVerificationEmail = ""
                    self.isLoading = false
                }
            }
        }

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
        let isDevAccount = Self.devWhitelist.contains(email.lowercased())
        guard isDevAccount || email.lowercased().hasSuffix("@bc.edu") else {
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
            try await result.user.sendEmailVerification()
            // auth state listener will set pendingVerification = true
        } catch {
            errorMessage = friendlyAuthError(error)
        }
    }

    func signIn(email: String, password: String) async {
        errorMessage = nil
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            if result.user.isEmailVerified {
                await fetchUser(uid: result.user.uid)
            } else {
                pendingVerification = true
                pendingVerificationEmail = result.user.email ?? ""
                isLoading = false
            }
        } catch {
            errorMessage = friendlyAuthError(error)
        }
    }

    func refreshVerificationStatus() async {
        errorMessage = nil
        do {
            try await Auth.auth().currentUser?.reload()
            guard let firebaseUser = Auth.auth().currentUser else { return }
            if firebaseUser.isEmailVerified {
                pendingVerification = false
                await fetchUser(uid: firebaseUser.uid)
            } else {
                errorMessage = "Email not verified yet. Check your @bc.edu inbox."
            }
        } catch {
            errorMessage = friendlyAuthError(error)
        }
    }

    func resendVerificationEmail() async {
        errorMessage = nil
        do {
            try await Auth.auth().currentUser?.sendEmailVerification()
        } catch {
            errorMessage = friendlyAuthError(error)
        }
    }

    func deleteAccount(rides: [Ride]) async {
        guard let user = currentUser, let firebaseUser = Auth.auth().currentUser else { return }
        errorMessage = nil
        do {
            for ride in rides where ride.riders[user.id] != nil && ride.creatorId != user.id {
                guard let rideId = ride.id else { continue }
                try? await db.collection("rides").document(rideId).updateData([
                    "riders.\(user.id)": FieldValue.delete()
                ])
            }
            let snapshot = try await db.collection("rides")
                .whereField("creatorId", isEqualTo: user.id)
                .getDocuments()
            for doc in snapshot.documents {
                try? await db.collection("rides").document(doc.documentID).delete()
            }
            try await db.collection("users").document(user.id).delete()
            try await firebaseUser.delete()
            currentUser = nil
            pendingVerification = false
        } catch {
            errorMessage = friendlyAuthError(error)
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
            errorMessage = friendlyAuthError(error)
        }
    }

    func signOut() {
        try? Auth.auth().signOut()
        currentUser = nil
        pendingVerification = false
        pendingVerificationEmail = ""
    }

    private func friendlyAuthError(_ error: Error) -> String {
        let code = (error as NSError).code
        switch AuthErrorCode(rawValue: code) {
        case .wrongPassword, .userNotFound, .invalidCredential, .invalidEmail:
            return "Incorrect email or password."
        case .emailAlreadyInUse:
            return "An account with this email already exists."
        case .weakPassword:
            return "Password must be at least 6 characters."
        case .tooManyRequests:
            return "Too many attempts. Please try again later."
        case .networkError:
            return "Network error. Please check your connection."
        case .userDisabled:
            return "This account has been disabled. Contact support."
        default:
            return "Something went wrong. Please try again."
        }
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
