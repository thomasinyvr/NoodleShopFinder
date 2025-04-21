import Foundation
import UserNotifications
import FirebaseMessaging
import FirebaseFirestore

class NotificationService: NSObject, ObservableObject {
    static let shared = NotificationService()
    @Published var notificationPermissionStatus: UNAuthorizationStatus = .notDetermined
    
    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }
    
    func requestNotificationPermission() async throws {
        let options: UNAuthorizationOptions = [.alert, .badge, .sound]
        let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: options)
        
        if granted {
            await MainActor.run {
                notificationPermissionStatus = .authorized
            }
            await UIApplication.shared.registerForRemoteNotifications()
        } else {
            await MainActor.run {
                notificationPermissionStatus = .denied
            }
        }
    }
    
    func checkNotificationPermission() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        await MainActor.run {
            notificationPermissionStatus = settings.authorizationStatus
        }
    }
    
    func scheduleLocalNotification(title: String, body: String, identifier: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    func handleBadgeAchievement(badge: BadgeDefinition, level: BadgeLevel) {
        let title = "New Badge Unlocked!"
        let body = "You've earned the \(level.rawValue.capitalized) \(badge.name) badge!"
        scheduleLocalNotification(title: title, body: body, identifier: "badge_\(badge.id)_\(level.rawValue)")
    }
    
    func handleNewReview(shopName: String, reviewerName: String) {
        let title = "New Review"
        let body = "\(reviewerName) reviewed \(shopName)"
        scheduleLocalNotification(title: title, body: body, identifier: "review_\(Date().timeIntervalSince1970)")
    }
    
    func handleWeeklyDigest() {
        let title = "Your Weekly Noodle Digest"
        let body = "Check out what's new in your favorite noodle shops this week!"
        scheduleLocalNotification(title: title, body: body, identifier: "weekly_digest_\(Date().timeIntervalSince1970)")
    }
    
    func updateFCMToken() {
        Messaging.messaging().token { token, error in
            if let error = error {
                print("Error fetching FCM registration token: \(error)")
            } else if let token = token {
                print("FCM registration token: \(token)")
                // Store the token in Firestore for the current user
                Task {
                    try? await self.storeFCMToken(token)
                }
            }
        }
    }
    
    private func storeFCMToken(_ token: String) async throws {
        guard let userId = await UserService.shared.currentUser?.id else { return }
        
        let userRef = Firestore.firestore().collection("users").document(userId)
        try await userRef.updateData([
            "fcmToken": token
        ])
    }
}

extension NotificationService: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                              willPresent notification: UNNotification,
                              withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show notifications even when the app is in the foreground
        completionHandler([.banner, .sound])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                              didReceive response: UNNotificationResponse,
                              withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        
        // Handle notification tap
        if let shopId = userInfo["shopId"] as? String {
            // Navigate to the shop
            NotificationCenter.default.post(name: NSNotification.Name("NavigateToShop"),
                                          object: nil,
                                          userInfo: ["shopId": shopId])
        }
        
        completionHandler()
    }
} 
