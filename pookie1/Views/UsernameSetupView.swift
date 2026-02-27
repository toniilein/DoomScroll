import SwiftUI

struct UsernameSetupView: View {
    @EnvironmentObject var firebaseManager: FirebaseManager
    @State private var displayName = ""
    @State private var username = ""
    @State private var errorMessage = ""
    @State private var isSaving = false

    var body: some View {
        ZStack {
            BrainRotTheme.background.ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                Text("\u{1F9E0}")
                    .font(.system(size: 60))

                Text("Set Up Your Profile")
                    .font(.title2.bold())
                    .foregroundColor(BrainRotTheme.textPrimary)

                VStack(spacing: 16) {
                    TextField("Display Name", text: $displayName)
                        .textFieldStyle(.plain)
                        .padding()
                        .background(BrainRotTheme.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .foregroundColor(BrainRotTheme.textPrimary)

                    TextField("Username", text: $username)
                        .textFieldStyle(.plain)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .padding()
                        .background(BrainRotTheme.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .foregroundColor(BrainRotTheme.textPrimary)

                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(BrainRotTheme.neonPink)
                    }
                }
                .padding(.horizontal, 32)

                Button {
                    save()
                } label: {
                    if isSaving {
                        ProgressView()
                            .tint(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else {
                        Text("Let's Go")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                }
                .background(isValid ? BrainRotTheme.accentGradient : LinearGradient(
                    colors: [Color.gray], startPoint: .leading, endPoint: .trailing
                ))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .disabled(!isValid || isSaving)
                .padding(.horizontal, 32)

                Spacer()
            }
        }
    }

    private var isValid: Bool {
        !displayName.trimmingCharacters(in: .whitespaces).isEmpty &&
        username.count >= 3
    }

    private func save() {
        isSaving = true
        errorMessage = ""
        Task {
            let success = await firebaseManager.setupUsername(
                displayName: displayName.trimmingCharacters(in: .whitespaces),
                username: username.trimmingCharacters(in: .whitespaces).lowercased()
            )
            if !success {
                errorMessage = "Username already taken. Try another one."
            }
            isSaving = false
        }
    }
}
