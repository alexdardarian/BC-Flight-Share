import SwiftUI

struct AuthView: View {
    @Environment(AuthViewModel.self) private var authVM
    @State private var showSignUp = false

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 12) {
                Image(systemName: "airplane.circle.fill")
                    .font(.system(size: 72))
                    .foregroundStyle(Color.bcGold)

                Text("BC Flight Share")
                    .font(.largeTitle.bold())
                    .foregroundStyle(.white)

                Text("Find BC students flying the same day.\nSplit the ride. Save money.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 80)
            .padding(.bottom, 48)
            .background(Color.bcMaroon)

            HStack(spacing: 0) {
                tabButton(title: "Sign In", isActive: !showSignUp) { showSignUp = false }
                tabButton(title: "Create Account", isActive: showSignUp) { showSignUp = true }
            }
            .background(Color(.systemGray6))

            if showSignUp {
                SignUpForm()
            } else {
                SignInForm()
            }

            Spacer()
        }
        .ignoresSafeArea(edges: .top)
    }

    private func tabButton(title: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(isActive ? Color.bcMaroon : Color.clear)
                .foregroundStyle(isActive ? .white : .secondary)
        }
    }
}

struct SignInForm: View {
    @Environment(AuthViewModel.self) private var authVM
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false

    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 14) {
                TextField("BC Email (@bc.edu)", text: $email)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .textContentType(.emailAddress)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)

                SecureField("Password", text: $password)
                    .textContentType(.password)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
            }

            if let error = authVM.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }

            Button {
                isLoading = true
                Task {
                    await authVM.signIn(email: email, password: password)
                    isLoading = false
                }
            } label: {
                Group {
                    if isLoading {
                        ProgressView().tint(.white)
                    } else {
                        Text("Sign In").font(.headline)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.bcMaroon)
                .foregroundStyle(.white)
                .cornerRadius(12)
            }
            .disabled(email.isEmpty || password.isEmpty || isLoading)
        }
        .padding(24)
    }
}

struct SignUpForm: View {
    @Environment(AuthViewModel.self) private var authVM
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var gender = "Prefer not to say"
    @State private var grade = "Freshman"
    @State private var dorm = "Gonzaga Hall"
    @State private var isLoading = false

    private let genders = ["Male", "Female", "Non-binary", "Prefer not to say"]

    private let grades = ["Freshman", "Sophomore", "Junior", "Senior", "Graduate"]

    private let dorms = [
        "Gonzaga Hall", "Kostka Hall", "Loyola Hall", "More Hall",
        "Cheverus Hall", "Fenwick Hall", "Hardey Hall", "Xavier Hall",
        "Voute Hall", "Fitzpatrick Hall", "Edmonds Hall", "Rubenstein Hall",
        "Smith Hall", "Duchesne Hall", "Medeiros Hall", "Clement Hall",
        "Keyes Hall", "Claver Hall", "Wahconah Hall", "90 St. Thomas More",
        "Newton Campus", "Off Campus"
    ]

    private var passwordMismatch: Bool {
        !confirmPassword.isEmpty && password != confirmPassword
    }

    private var isValid: Bool {
        !name.isEmpty && !email.isEmpty && password.count >= 6 && !passwordMismatch
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(spacing: 14) {
                    TextField("Full Name", text: $name)
                        .textContentType(.name)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)

                    TextField("BC Email (@bc.edu)", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .textContentType(.emailAddress)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)

                    SecureField("Password (min 6 characters)", text: $password)
                        .textContentType(.newPassword)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)

                    SecureField("Confirm Password", text: $confirmPassword)
                        .textContentType(.newPassword)
                        .padding()
                        .background(
                            confirmPassword.isEmpty ? Color(.systemGray6) :
                            passwordMismatch ? Color.red.opacity(0.1) : Color.green.opacity(0.08)
                        )
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(passwordMismatch ? Color.red.opacity(0.5) : Color.clear, lineWidth: 1)
                        )
                }

                // Gender
                pickerRow(label: "Gender", systemImage: "person.fill") {
                    Picker("Gender", selection: $gender) {
                        ForEach(genders, id: \.self) { Text($0).tag($0) }
                    }
                    .pickerStyle(.segmented)
                }

                // Grade
                pickerRow(label: "Year", systemImage: "graduationcap.fill") {
                    Picker("Year", selection: $grade) {
                        ForEach(grades, id: \.self) { Text($0).tag($0) }
                    }
                    .pickerStyle(.segmented)
                }

                // Dorm
                pickerRow(label: "Dorm / Housing", systemImage: "building.2.fill") {
                    Picker("Dorm", selection: $dorm) {
                        ForEach(dorms, id: \.self) { Text($0).tag($0) }
                    }
                    .tint(Color.bcMaroon)
                }

                if let error = authVM.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                }

                Button {
                    isLoading = true
                    Task {
                        await authVM.signUp(
                            name: name,
                            email: email,
                            password: password,
                            gender: gender,
                            grade: grade,
                            dorm: dorm
                        )
                        isLoading = false
                    }
                } label: {
                    Group {
                        if isLoading {
                            ProgressView().tint(.white)
                        } else {
                            Text("Create Account").font(.headline)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isValid ? Color.bcMaroon : Color(.systemGray4))
                    .foregroundStyle(.white)
                    .cornerRadius(12)
                }
                .disabled(!isValid || isLoading)
            }
            .padding(24)
        }
    }

    private func pickerRow<Content: View>(
        label: String,
        systemImage: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(label, systemImage: systemImage)
                .font(.subheadline.bold())
                .foregroundStyle(.secondary)
            content()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

#Preview {
    AuthView()
        .environment(AuthViewModel())
}
