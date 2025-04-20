//
//  UpdatePhotoReferences.swift
//  NoodleShopFinder
//
//  Created by Thomas Friesman on 2025-04-19.
//

import Foundation
import FirebaseFirestore

struct PhotoReferenceUpdater {
    static func updatePhotoReferences() {
        let db = Firestore.firestore()
        
        print("🔍 Starting photo reference update...")
        
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
                
                // Get the current photo_url
                guard let photoURL = data["photo_url"] as? String else {
                    print("⚠️ No photo_url found for document \(document.documentID)")
                    continue
                }
                
                // Extract the photoreference from the URL
                guard let photoReference = extractPhotoReference(from: photoURL) else {
                    print("⚠️ Could not extract photo reference from URL: \(photoURL)")
                    continue
                }
                
                // Update the document
                document.reference.updateData([
                    "photo_reference": photoReference
                ]) { error in
                    if let error = error {
                        print("❌ Error updating document \(document.documentID): \(error.localizedDescription)")
                    } else {
                        print("✅ Successfully updated document \(document.documentID)")
                    }
                }
            }
        }
    }
    
    private static func extractPhotoReference(from url: String) -> String? {
        // Split the URL by "photoreference="
        guard let range = url.range(of: "photoreference=") else { return nil }
        
        // Get the part after "photoreference="
        let afterReference = url[range.upperBound...]
        
        // Split by "&" to get just the reference
        let components = afterReference.components(separatedBy: "&")
        guard !components.isEmpty else { return nil }
        
        return components[0]
    }
}

// To run this, call this from your app's initialization
// PhotoReferenceUpdater.updatePhotoReferences()
