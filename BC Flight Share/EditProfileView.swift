import SwiftUI

struct EditProfileView: View {
    @Environment(AuthViewModel.self) private var authVM
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var gender: String
    @State private var grade: String
    @State private var dorm: String
    @State private var isSaving = false

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

    init(user: BCUser) {
        _name = State(initialValue: user.name)
        _gender = State(initialValue: user.gender)
        _grade = State(initialValue: user.grade)
        _dorm = State(initialValue: user.dorm)
    }

    private var nameIsValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Your name", text: $name)
                }

                Section("Gender") {
                    Picker("Gender", selection: $gender) {
                        ForEach(genders, id: \.self) { Text($0).tag($0) }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Year") {
                    Picker("Grade", selection: $grade) {
                        ForEach(grades, id: \.self) { Text($0).tag($0) }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Where do you live?") {
                    Picker("Dorm", selection: $dorm) {
                        ForEach(dorms, id: \.self) { Text($0).tag($0) }
                    }
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        isSaving = true
                        Task {
                            await authVM.updateProfile(
                                name: name,
                                gender: gender,
                                grade: grade,
                                dorm: dorm
                            )
                            dismiss()
                        }
                    }
                    .disabled(!nameIsValid || isSaving)
                }
            }
        }
    }
}
