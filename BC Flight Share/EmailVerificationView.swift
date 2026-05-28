import SwiftUI

struct EmailVerificationView: View {
    @Environment(AuthViewModel.self) private var authVM
    @State private var isChecking = false
    @State private var isResending = false
    @State private var resendCooldown = 0

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 12) {
                Image(systemName: "envelope.badge.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(Color.bcGold)

                Text("Verify Your BC Email")
                    .font(.title2.bold())
                    .foregroundStyle(.white)

                Text("Check your @bc.edu inbox and tap the confirmation link we sent.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 72)
            .padding(.bottom, 40)
            .padding(.horizontal, 32)
            .background(Color.bcMaroon)

            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Sent to")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(authVM.pendingVerificationEmail)
                        .font(.subheadline.bold())
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)

                if let error = authVM.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                }

                Button {
                    isChecking = true
                    Task {
                        await authVM.refreshVerificationStatus()
                        isChecking = false
                    }
                } label: {
                    Group {
                        if isChecking {
                            ProgressView().tint(.white)
                        } else {
                            Text("I've Verified My Email").font(.headline)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.bcMaroon)
                    .foregroundStyle(.white)
                    .cornerRadius(12)
                }
                .disabled(isChecking)

                Button {
                    guard !isResending && resendCooldown == 0 else { return }
                    isResending = true
                    resendCooldown = 30
                    Task {
                        await authVM.resendVerificationEmail()
                        isResending = false
                        while resendCooldown > 0 {
                            try? await Task.sleep(for: .seconds(1))
                            resendCooldown -= 1
                        }
                    }
                } label: {
                    Text(resendCooldown > 0 ? "Resend in \(resendCooldown)s" : "Resend Email")
                        .font(.subheadline)
                        .foregroundStyle(resendCooldown > 0 ? .secondary : Color.bcMaroon)
                }
                .disabled(isResending || resendCooldown > 0)

                Button {
                    authVM.signOut()
                } label: {
                    Text("Use a different account")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(24)

            Spacer()
        }
        .ignoresSafeArea(edges: .top)
    }
}
