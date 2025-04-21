import Foundation
import FirebaseFirestore

class SocialService {
    static let shared = SocialService()
    private let db = Firestore.firestore()
    
    private init() {}
    
    // MARK: - Following
    
    func followUser(_ userId: String) async throws {
        guard let currentUserId = await UserService.shared.currentUser?.id else {
            throw NSError(domain: "SocialService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        let batch = db.batch()
        
        // Add to current user's following list
        let currentUserRef = db.collection("users").document(currentUserId)
        batch.updateData([
            "social.following": FieldValue.arrayUnion([userId])
        ], forDocument: currentUserRef)
        
        // Add to target user's followers list
        let targetUserRef = db.collection("users").document(userId)
        batch.updateData([
            "social.followers": FieldValue.arrayUnion([currentUserId])
        ], forDocument: targetUserRef)
        
        try await batch.commit()
    }
    
    func unfollowUser(_ userId: String) async throws {
        guard let currentUserId = await UserService.shared.currentUser?.id else {
            throw NSError(domain: "SocialService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        let batch = db.batch()
        
        // Remove from current user's following list
        let currentUserRef = db.collection("users").document(currentUserId)
        batch.updateData([
            "social.following": FieldValue.arrayRemove([userId])
        ], forDocument: currentUserRef)
        
        // Remove from target user's followers list
        let targetUserRef = db.collection("users").document(userId)
        batch.updateData([
            "social.followers": FieldValue.arrayRemove([currentUserId])
        ], forDocument: targetUserRef)
        
        try await batch.commit()
    }
    
    // MARK: - Blocking
    
    func blockUser(_ userId: String) async throws {
        guard let currentUserId = await UserService.shared.currentUser?.id else {
            throw NSError(domain: "SocialService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        let batch = db.batch()
        
        // Add to current user's blocked list
        let currentUserRef = db.collection("users").document(currentUserId)
        batch.updateData([
            "social.blockedUsers": FieldValue.arrayUnion([userId])
        ], forDocument: currentUserRef)
        
        // Remove from following/followers if necessary
        batch.updateData([
            "social.following": FieldValue.arrayRemove([userId]),
            "social.followers": FieldValue.arrayRemove([userId])
        ], forDocument: currentUserRef)
        
        try await batch.commit()
    }
    
    func unblockUser(_ userId: String) async throws {
        guard let currentUserId = await UserService.shared.currentUser?.id else {
            throw NSError(domain: "SocialService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        let currentUserRef = db.collection("users").document(currentUserId)
        try await currentUserRef.updateData([
            "social.blockedUsers": FieldValue.arrayRemove([userId])
        ])
    }
    
    // MARK: - Sharing
    
    func shareShop(_ shopId: String, with userIds: [String]) async throws {
        guard let currentUserId = await UserService.shared.currentUser?.id else {
            throw NSError(domain: "SocialService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        let batch = db.batch()
        
        // Create a share record for each recipient
        for userId in userIds {
            let shareRef = db.collection("shares").document()
            let shareData: [String: Any] = [
                "id": shareRef.documentID,
                "shopId": shopId,
                "senderId": currentUserId,
                "recipientId": userId,
                "timestamp": FieldValue.serverTimestamp(),
                "read": false
            ]
            batch.setData(shareData, forDocument: shareRef)
        }
        
        // Update sender's statistics
        let currentUserRef = db.collection("users").document(currentUserId)
        batch.updateData([
            "statistics.totalShares": FieldValue.increment(Int64(userIds.count))
        ], forDocument: currentUserRef)
        
        try await batch.commit()
    }
    
    // MARK: - Queries
    
    func getFollowers(for userId: String) async throws -> [UserProfile] {
        let userRef = db.collection("users").document(userId)
        let userDoc = try await userRef.getDocument()
        
        guard let data = userDoc.data(),
              let followerIds = data["social.followers"] as? [String] else {
            return []
        }
        
        var followers: [UserProfile] = []
        for followerId in followerIds {
            if let follower = try await getUserProfile(followerId) {
                followers.append(follower)
            }
        }
        
        return followers
    }
    
    func getFollowing(for userId: String) async throws -> [UserProfile] {
        let userRef = db.collection("users").document(userId)
        let userDoc = try await userRef.getDocument()
        
        guard let data = userDoc.data(),
              let followingIds = data["social.following"] as? [String] else {
            return []
        }
        
        var following: [UserProfile] = []
        for followingId in followingIds {
            if let user = try await getUserProfile(followingId) {
                following.append(user)
            }
        }
        
        return following
    }
    
    private func getUserProfile(_ userId: String) async throws -> UserProfile? {
        let docRef = db.collection("users").document(userId)
        let document = try await docRef.getDocument()
        
        guard let data = document.data() else { return nil }
        
        let jsonData = try JSONSerialization.data(withJSONObject: data)
        return try JSONDecoder().decode(UserProfile.self, from: jsonData)
    }
} 