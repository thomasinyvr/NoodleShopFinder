import Foundation
import FirebaseFirestore

@MainActor
class BadgeProgressService: ObservableObject {
    static let shared = BadgeProgressService()
    
    private let db = Firestore.firestore()

    @Published var progressList: [UserBadgeProgress] = []

    /// Fetch badge progress and listen for real-time updates
    func fetchBadgeProgress(for userId: String) {
        let badgeCollection = db.collection("users").document(userId).collection("badges")

        badgeCollection.addSnapshotListener { [weak self] snapshot, error in
            guard let self = self else { return }
            guard let documents = snapshot?.documents else {
                print("⚠️ Error fetching badge progress: \(error?.localizedDescription ?? "Unknown error")")
                return
            }

            self.progressList = documents.compactMap { doc in
                try? doc.data(as: UserBadgeProgress.self)
            }
        }
    }

    /// Save or update a user's badge progress
    func updateBadgeProgress(for userId: String, badgeId: String, newCount: Int) async {
        let badgeRef = db.collection("users").document(userId).collection("badges").document(badgeId)

        // Get the definition from catalog
        guard let definition = BadgeCatalog.all.first(where: { $0.id == badgeId }) else {
            print("⚠️ No badge definition found for ID: \(badgeId)")
            return
        }

        // Determine the highest level achieved
        let achievedLevel = definition.tiers
            .sorted(by: { $0.threshold > $1.threshold })
            .first(where: { newCount >= $0.threshold })?.level

        let progress = UserBadgeProgress(id: badgeId, currentCount: newCount, achievedLevel: achievedLevel)

        do {
            try badgeRef.setData(from: progress)
            print("✅ Badge '\(badgeId)' updated with count \(newCount) and level '\(achievedLevel?.rawValue ?? "none")'")
        } catch {
            print("❌ Failed to update badge '\(badgeId)': \(error.localizedDescription)")
        }
    }

    /// Manually fetch one badge (optional utility)
    func fetchSingleBadge(for userId: String, badgeId: String) async -> UserBadgeProgress? {
        let badgeRef = db.collection("users").document(userId).collection("badges").document(badgeId)

        do {
            let badge = try await badgeRef.getDocument(as: UserBadgeProgress.self)
            return badge
        } catch {
            print("❌ Failed to fetch badge '\(badgeId)': \(error.localizedDescription)")
            return nil
        }
    }
}
