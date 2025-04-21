import Foundation
import FirebaseAuth
import FirebaseFirestore

struct UserProfile: Codable, Identifiable {
    let id: String
    var displayName: String
    var email: String
    var photoURL: String?
    var joinedDate: Date
    var lastActive: Date
    var preferences: UserPreferences
    var statistics: UserStatistics
    var social: UserSocial
    
    struct UserPreferences: Codable {
        var favoriteCuisines: [String]
        var notificationSettings: NotificationSettings
        var theme: AppTheme
        
        struct NotificationSettings: Codable {
            enum Setting: String, Codable {
                case badgeAchievements
                case newReviews
                case weeklyDigest
            }
            
            var badgeAchievements: Bool
            var newReviews: Bool
            var weeklyDigest: Bool
        }
        
        enum AppTheme: String, Codable {
            case light
            case dark
            case system
        }
    }
    
    struct UserStatistics: Codable {
        var totalVisits: Int
        var totalReviews: Int
        var totalPhotos: Int
        var totalShares: Int
        var favoriteShops: [String] // Shop IDs
        var visitedShops: [String: Date] // Shop ID: Last visit date
    }
    
    struct UserSocial: Codable {
        var followers: [String] // User IDs
        var following: [String] // User IDs
        var blockedUsers: [String] // User IDs
    }
}

@MainActor
class UserService: ObservableObject {
    static let shared = UserService()
    
    @Published var currentUser: UserProfile?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var error: Error?
    
    private let auth = Auth.auth()
    private let db = Firestore.firestore()
    private var authStateListener: AuthStateDidChangeListenerHandle?
    
    init() {
        setupAuthStateListener()
    }
    
    deinit {
        if let listener = authStateListener {
            auth.removeStateDidChangeListener(listener)
        }
    }
    
    private func setupAuthStateListener() {
        authStateListener = auth.addStateDidChangeListener { [weak self] _, user in
            guard let self = self else { return }
            
            if let user = user {
                self.isAuthenticated = true
                Task {
                    do {
                        try await self.fetchUserProfile(userId: user.uid)
                    } catch {
                        print("Error fetching user profile: \(error.localizedDescription)")
                    }
                }
            } else {
                self.isAuthenticated = false
                self.currentUser = nil
            }
        }
    }
    
    func signIn(email: String, password: String) async throws {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let result = try await auth.signIn(withEmail: email, password: password)
            try await fetchUserProfile(userId: result.user.uid)
        } catch {
            self.error = error
            throw error
        }
    }
    
    func signUp(email: String, password: String, displayName: String) async throws {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let result = try await auth.createUser(withEmail: email, password: password)
            
            // Create initial user profile
            let userProfile = UserProfile(
                id: result.user.uid,
                displayName: displayName,
                email: email,
                photoURL: nil,
                joinedDate: Date(),
                lastActive: Date(),
                preferences: UserProfile.UserPreferences(
                    favoriteCuisines: [],
                    notificationSettings: UserProfile.UserPreferences.NotificationSettings(
                        badgeAchievements: true,
                        newReviews: true,
                        weeklyDigest: true
                    ),
                    theme: .system
                ),
                statistics: UserProfile.UserStatistics(
                    totalVisits: 0,
                    totalReviews: 0,
                    totalPhotos: 0,
                    totalShares: 0,
                    favoriteShops: [],
                    visitedShops: [:]
                ),
                social: UserProfile.UserSocial(
                    followers: [],
                    following: [],
                    blockedUsers: []
                )
            )
            
            try await saveUserProfile(userProfile)
            self.currentUser = userProfile
        } catch {
            self.error = error
            throw error
        }
    }
    
    func signOut() throws {
        do {
            try auth.signOut()
            currentUser = nil
        } catch {
            self.error = error
            throw error
        }
    }
    
    private func fetchUserProfile(userId: String) async throws {
        let docRef = db.collection("users").document(userId)
        let document = try await docRef.getDocument()
        
        guard let data = document.data() else {
            throw NSError(domain: "UserService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No user data found"])
        }
        
        let jsonData = try JSONSerialization.data(withJSONObject: data)
        let userProfile = try JSONDecoder().decode(UserProfile.self, from: jsonData)
        
        self.currentUser = userProfile
    }
    
    private func saveUserProfile(_ profile: UserProfile) async throws {
        let docRef = db.collection("users").document(profile.id)
        
        let data = try JSONEncoder().encode(profile)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        
        try await docRef.setData(json)
    }
    
    func updateUserProfile(_ profile: UserProfile) async throws {
        try await saveUserProfile(profile)
        self.currentUser = profile
    }
    
    func updateLastActive() async throws {
        guard var user = currentUser else { return }
        user.lastActive = Date()
        try await updateUserProfile(user)
    }
} 