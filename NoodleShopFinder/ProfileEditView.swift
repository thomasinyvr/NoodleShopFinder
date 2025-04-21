import SwiftUI
import PhotosUI

struct SettingsView: View {
    @StateObject private var userService = UserService.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var displayName: String
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var profileImage: Image?
    @State private var favoriteCuisines: [String]
    @State private var newCuisine = ""
    @State private var showError = false
    @State private var errorMessage = ""
    
    init() {
        let user = UserService.shared.currentUser
        _displayName = State(initialValue: user?.displayName ?? "")
        _favoriteCuisines = State(initialValue: user?.preferences.favoriteCuisines ?? [])
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Profile")) {
                    HStack {
                        Spacer()
                        if let profileImage = profileImage {
                            profileImage
                                .resizable()
                                .scaledToFill()
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                        } else {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .frame(width: 100, height: 100)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                    }
                    .padding(.vertical)
                    
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        Text("Change Photo")
                    }
                    
                    TextField("Display Name", text: $displayName)
                }
                
                Section(header: Text("Preferences")) {
                    Toggle("Show Beer Serving Status", isOn: .constant(true))
                    Toggle("Show Opening Hours", isOn: .constant(true))
                    
                    if let user = userService.currentUser {
                        Toggle("Badge Achievements", isOn: Binding(
                            get: { user.preferences.notificationSettings.badgeAchievements },
                            set: { newValue in
                                updateNotificationSetting(.badgeAchievements, value: newValue)
                            }
                        ))
                        
                        Toggle("New Reviews", isOn: Binding(
                            get: { user.preferences.notificationSettings.newReviews },
                            set: { newValue in
                                updateNotificationSetting(.newReviews, value: newValue)
                            }
                        ))
                        
                        Toggle("Weekly Digest", isOn: Binding(
                            get: { user.preferences.notificationSettings.weeklyDigest },
                            set: { newValue in
                                updateNotificationSetting(.weeklyDigest, value: newValue)
                            }
                        ))
                    }
                }
                
                Section(header: Text("Appearance")) {
                    if let user = userService.currentUser {
                        Picker("Theme", selection: Binding(
                            get: { user.preferences.theme },
                            set: { newValue in
                                updateTheme(newValue)
                            }
                        )) {
                            Text("Light").tag(UserProfile.UserPreferences.AppTheme.light)
                            Text("Dark").tag(UserProfile.UserPreferences.AppTheme.dark)
                            Text("System").tag(UserProfile.UserPreferences.AppTheme.system)
                        }
                    }
                }
                
                Section(header: Text("Favorite Cuisines")) {
                    ForEach(favoriteCuisines, id: \.self) { cuisine in
                        Text(cuisine)
                    }
                    .onDelete { indexSet in
                        favoriteCuisines.remove(atOffsets: indexSet)
                    }
                    
                    HStack {
                        TextField("Add Cuisine", text: $newCuisine)
                        Button("Add") {
                            if !newCuisine.isEmpty && !favoriteCuisines.contains(newCuisine) {
                                favoriteCuisines.append(newCuisine)
                                newCuisine = ""
                            }
                        }
                    }
                }
                
                Section(header: Text("About")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.gray)
                    }
                    
                    Link(destination: URL(string: "https://example.com/privacy")!) {
                        HStack {
                            Text("Privacy Policy")
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .font(.caption)
                        }
                    }
                    
                    Link(destination: URL(string: "https://example.com/terms")!) {
                        HStack {
                            Text("Terms of Service")
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .font(.caption)
                        }
                    }
                }
                
                Section {
                    Button(action: {
                        do {
                            try userService.signOut()
                        } catch {
                            errorMessage = error.localizedDescription
                            showError = true
                        }
                    }) {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                            Text("Sign Out")
                        }
                        .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveProfile()
                    }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .onChange(of: selectedPhoto) { _, _ in
                Task {
                    if let data = try? await selectedPhoto?.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        profileImage = Image(uiImage: uiImage)
                        // Here you would upload the image to Firebase Storage
                        // and update the user's photoURL
                    }
                }
            }
        }
    }
    
    private func saveProfile() {
        guard var user = userService.currentUser else { return }
        
        Task {
            do {
                user.displayName = displayName
                user.preferences.favoriteCuisines = favoriteCuisines
                try await userService.updateUserProfile(user)
                dismiss()
            } catch {
                showError = true
                errorMessage = error.localizedDescription
            }
        }
    }
    
    private func updateNotificationSetting(_ setting: UserProfile.UserPreferences.NotificationSettings.Setting, value: Bool) {
        guard var user = userService.currentUser else { return }
        
        Task {
            do {
                switch setting {
                case .badgeAchievements:
                    user.preferences.notificationSettings.badgeAchievements = value
                case .newReviews:
                    user.preferences.notificationSettings.newReviews = value
                case .weeklyDigest:
                    user.preferences.notificationSettings.weeklyDigest = value
                }
                try await userService.updateUserProfile(user)
            } catch {
                showError = true
                errorMessage = error.localizedDescription
            }
        }
    }
    
    private func updateTheme(_ theme: UserProfile.UserPreferences.AppTheme) {
        guard var user = userService.currentUser else { return }
        
        Task {
            do {
                user.preferences.theme = theme
                try await userService.updateUserProfile(user)
            } catch {
                showError = true
                errorMessage = error.localizedDescription
            }
        }
    }
}

#Preview {
    SettingsView()
} 