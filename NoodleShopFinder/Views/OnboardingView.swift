import SwiftUI

struct OnboardingView: View {
    @StateObject private var userService = UserService.shared
    @State private var currentPage = 0
    @State private var email = ""
    @State private var password = ""
    @State private var displayName = ""
    @State private var errorMessage: String?
    @State private var isLoading = false
    
    private let pages = [
        OnboardingPage(
            title: "Welcome to Noodle Shop Finder",
            description: "Discover the best noodle shops in your area and share your experiences with fellow food enthusiasts.",
            imageName: "noodlebowl"
        ),
        OnboardingPage(
            title: "Track Your Progress",
            description: "Earn badges as you explore new noodle shops and share your reviews with the community.",
            imageName: "badge"
        ),
        OnboardingPage(
            title: "Join the Community",
            description: "Connect with other noodle lovers, share photos, and discover hidden gems together.",
            imageName: "person.3"
        )
    ]
    
    var body: some View {
        NavigationStack {
            if currentPage < pages.count {
                // Onboarding Pages
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        OnboardingPageView(page: pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(.page)
                .indexViewStyle(.page(backgroundDisplayMode: .always))
                .overlay(alignment: .bottom) {
                    Button(action: {
                        withAnimation {
                            currentPage += 1
                        }
                    }) {
                        Text(currentPage == pages.count - 1 ? "Get Started" : "Next")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                    .padding()
                }
            } else {
                // Sign Up Form
                ScrollView {
                    VStack(spacing: 20) {
                        Image(systemName: "noodlebox")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        
                        Text("Create Your Account")
                            .font(.title)
                            .bold()
                        
                        if let error = errorMessage {
                            Text(error)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Display Name")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            TextField("Enter your name", text: $displayName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            TextField("Enter your email", text: $email)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            SecureField("Enter your password", text: $password)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        Button(action: signUp) {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Sign Up")
                            }
                        }
                        .disabled(isLoading || email.isEmpty || password.isEmpty || displayName.isEmpty)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        
                        HStack {
                            Text("Already have an account?")
                            Button("Sign In") {
                                // TODO: Show sign in view
                            }
                        }
                        .font(.subheadline)
                    }
                    .padding()
                }
            }
        }
    }
    
    private func signUp() {
        guard !email.isEmpty, !password.isEmpty, !displayName.isEmpty else { return }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                try await userService.signUp(email: email, password: password, displayName: displayName)
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}

struct OnboardingPage: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let imageName: String
}

struct OnboardingPageView: View {
    let page: OnboardingPage
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: page.imageName)
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            Text(page.title)
                .font(.title)
                .bold()
                .multilineTextAlignment(.center)
            
            Text(page.description)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
    }
}

#Preview {
    OnboardingView()
} 