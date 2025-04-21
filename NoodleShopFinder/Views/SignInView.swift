import SwiftUI
import AuthenticationServices

struct SignInView: View {
    @StateObject private var userService = UserService.shared
    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = false
    @State private var displayName = ""
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Logo and title
                Image(systemName: "noodles")
                    .font(.system(size: 60))
                    .foregroundColor(.orange)
                
                Text("Noodle Shop Finder")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                // Form fields
                VStack(spacing: 15) {
                    if isSignUp {
                        TextField("Display Name", text: $displayName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.words)
                    }
                    
                    TextField("Email", text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    
                    SecureField("Password", text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .padding(.horizontal)
                
                // Sign in/up button
                Button(action: handleAuth) {
                    Text(isSignUp ? "Sign Up" : "Sign In")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                .disabled(userService.isLoading)
                
                // Toggle between sign in and sign up
                Button(action: { isSignUp.toggle() }) {
                    Text(isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                        .foregroundColor(.orange)
                }
                
                // Social sign-in options
                VStack(spacing: 10) {
                    Text("Or continue with")
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 20) {
                        SignInWithAppleButton(
                            onRequest: { request in
                                request.requestedScopes = [.fullName, .email]
                            },
                            onCompletion: { result in
                                handleAppleSignIn(result)
                            }
                        )
                        .frame(height: 44)
                        .cornerRadius(8)
                        
                        Button(action: handleGoogleSignIn) {
                            HStack {
                                Image("google_logo")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 20, height: 20)
                                Text("Google")
                                    .foregroundColor(.primary)
                            }
                            .frame(height: 44)
                            .frame(maxWidth: .infinity)
                            .background(Color.white)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding()
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .overlay {
                if userService.isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                }
            }
        }
    }
    
    private func handleAuth() {
        Task {
            do {
                if isSignUp {
                    try await userService.signUp(email: email, password: password, displayName: displayName)
                } else {
                    try await userService.signIn(email: email, password: password)
                }
            } catch {
                showError = true
                errorMessage = error.localizedDescription
            }
        }
    }
    
    private func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) {
        // Implement Apple Sign In
        // This requires additional setup in the app's capabilities and Info.plist
    }
    
    private func handleGoogleSignIn() {
        // Implement Google Sign In
        // This requires Google Sign-In SDK setup
    }
}

#Preview {
    SignInView()
} 