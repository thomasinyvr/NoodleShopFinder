import SwiftUI
import FirebaseCore
import FirebaseFirestore
import FirebaseStorage

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        print("Initializing Firebase...")
        FirebaseApp.configure()
        print("✅ Firebase initialized successfully")
        
        testFirestoreConnection()
        Task {
            await convertPhotoURLs()
        }
        return true
    }
    
    private func testFirestoreConnection() {
        let db = Firestore.firestore()
        db.collection("noodle_shops").limit(to: 1).getDocuments { snapshot, error in
            if let error = error {
                print("❌ Firestore test failed: \(error.localizedDescription)")
                if let firestoreError = error as NSError? {
                    print("Error code: \(firestoreError.code)")
                    print("Error domain: \(firestoreError.domain)")
                    print("Error user info: \(firestoreError.userInfo)")
                }
            } else {
                print("✅ Firestore connection successful")
            }
        }
    }
    
    @MainActor
    private func convertPhotoURLs() async {
        let db = Firestore.firestore()
        print("🔍 Starting photo URL conversion...")
        
        do {
            let snapshot = try await db.collection("noodle_shops").getDocuments()
            let documents = snapshot.documents
            print("📄 Found \(documents.count) documents to update")
            
            for document in documents {
                let documentData = document.data()
                let docID = document.documentID
                guard let photoURL = documentData["photo_url"] as? String else {
                    print("⚠️ No photo_url for \(docID)")
                    continue
                }
                
                if photoURL.hasPrefix("http") && !photoURL.contains("maps.googleapis.com") {
                    print("✅ Already direct image URL for \(docID)")
                    continue
                }
                
                guard let photoReference = extractPhotoReference(from: photoURL) else {
                    print("⚠️ Couldn't extract photo reference from \(photoURL)")
                    continue
                }
                
                let apiKey = Bundle.main.object(forInfoDictionaryKey: "API_KEY") as? String ?? ""
                let redirectURL = "https://maps.googleapis.com/maps/api/place/photo?maxwidth=800&photoreference=\(photoReference)&key=\(apiKey)"
                
                guard let url = URL(string: redirectURL) else {
                    print("❌ Invalid redirect URL")
                    continue
                }
                
                var request = URLRequest(url: url)
                request.setValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")
                
                let (responseData, response) = try await URLSession.shared.data(for: request)
                if let httpResponse = response as? HTTPURLResponse,
                   let location = httpResponse.allHeaderFields["Location"] as? String {
                    
                    try await document.reference.updateData([
                        "photo_url": location
                    ])
                    
                    print("✅ Updated \(docID) with direct image URL")
                } else {
                    print("⚠️ No redirect location found for \(docID)")
                }
            }
            
        } catch {
            print("❌ Error during URL conversion: \(error.localizedDescription)")
        }
    }

    private func extractPhotoReference(from url: String) -> String? {
        guard let range = url.range(of: "photoreference=") else { return nil }
        let after = url[range.upperBound...]
        return after.split(separator: "&").first.map(String.init)
    }
}

@main
struct NoodleShopFinderApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
