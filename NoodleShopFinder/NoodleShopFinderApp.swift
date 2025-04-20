import SwiftUI
import FirebaseCore
import FirebaseFirestore

@main
struct NoodleShopFinderApp: App {
    init() {
        print("Initializing Firebase...")
        do {
            try FirebaseApp.configure()
            print("✅ Firebase initialized successfully")
            
            // Test Firestore connection
            let db = Firestore.firestore()
            print("🔍 Testing Firestore connection...")
            db.collection("noodle_shops").getDocuments { snapshot, error in
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
        } catch {
            print("❌ Firebase initialization failed: \(error.localizedDescription)")
        }
        
        // Convert Google Places API URLs to direct image URLs
        convertPhotoURLs()
    }
    
    private func convertPhotoURLs() {
        let db = Firestore.firestore()
        
        print("🔍 Starting photo URL conversion...")
        
        db.collection("noodle_shops").getDocuments { snapshot, error in
            if let error = error {
                print("❌ Error fetching documents: \(error.localizedDescription)")
                return
            }
            
            guard let documents = snapshot?.documents else {
                print("❌ No documents found")
                return
            }
            
            print("📄 Found \(documents.count) documents to update")
            
            for document in documents {
                let data = document.data()
                print("\n📋 Document ID: \(document.documentID)")
                print("📋 Document data: \(data)")
                
                // Get the current photo_url
                guard let photoURL = data["photo_url"] as? String else {
                    print("⚠️ No photo_url found for document \(document.documentID)")
                    continue
                }
                
                // If it's already a direct image URL, skip it
                if photoURL.hasPrefix("http") && !photoURL.contains("maps.googleapis.com") {
                    print("✅ Already a direct image URL: \(photoURL)")
                    continue
                }
                
                // Extract the photoreference from the URL
                guard let photoReference = extractPhotoReference(from: photoURL) else {
                    print("⚠️ Could not extract photo reference from URL: \(photoURL)")
                    continue
                }
                
                // Construct the new URL
                let apiKey = Bundle.main.object(forInfoDictionaryKey: "GMSPlacesClientAPIKey") as? String ?? ""
                let newURL = "https://maps.googleapis.com/maps/api/place/photo?maxwidth=800&photo_reference=\(photoReference)&key=\(apiKey)"
                
                // First, try to get the actual image URL by following the redirect
                let config = URLSessionConfiguration.default
                config.httpAdditionalHeaders = [
                    "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15",
                    "Accept": "image/*,*/*;q=0.8",
                    "Referer": "https://maps.googleapis.com/"
                ]
                
                let session = URLSession(configuration: config)
                let task = session.dataTask(with: URL(string: newURL)!) { _, response, _ in
                    if let httpResponse = response as? HTTPURLResponse,
                       let location = httpResponse.allHeaderFields["Location"] as? String {
                        print("🔄 Found redirect URL: \(location)")
                        
                        // Update the document with the direct image URL
                        document.reference.updateData([
                            "photo_url": location
                        ]) { error in
                            if let error = error {
                                print("❌ Error updating document \(document.documentID): \(error.localizedDescription)")
                            } else {
                                print("✅ Successfully updated document \(document.documentID) with direct image URL")
                            }
                        }
                    }
                }
                task.resume()
            }
        }
    }
    
    private func extractPhotoReference(from url: String) -> String? {
        // Split the URL by "photo_reference="
        guard let range = url.range(of: "photo_reference=") else { return nil }
        
        // Get the part after "photo_reference="
        let afterReference = url[range.upperBound...]
        
        // Split by "&" to get just the reference
        let components = afterReference.components(separatedBy: "&")
        guard !components.isEmpty else { return nil }
        
        return components[0]
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
