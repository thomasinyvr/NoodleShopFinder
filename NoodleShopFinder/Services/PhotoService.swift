import Foundation
import FirebaseStorage
import UIKit

class PhotoService {
    static let shared = PhotoService()
    private let storage = Storage.storage()
    
    private init() {}
    
    func uploadProfilePhoto(_ image: UIImage, userId: String) async throws -> String {
        // Resize image to reduce upload size
        let resizedImage = image.resized(to: CGSize(width: 500, height: 500))
        guard let imageData = resizedImage.jpegData(compressionQuality: 0.8) else {
            throw NSError(domain: "PhotoService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to data"])
        }
        
        // Create a unique filename
        let filename = "\(userId)_\(Date().timeIntervalSince1970).jpg"
        let storageRef = storage.reference().child("profile_photos/\(filename)")
        
        // Upload the image
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        let _ = try await storageRef.putDataAsync(imageData, metadata: metadata)
        
        // Get the download URL
        let downloadURL = try await storageRef.downloadURL()
        return downloadURL.absoluteString
    }
    
    func uploadShopPhoto(_ image: UIImage, shopId: String, userId: String) async throws -> String {
        // Resize image to reduce upload size
        let resizedImage = image.resized(to: CGSize(width: 800, height: 800))
        guard let imageData = resizedImage.jpegData(compressionQuality: 0.8) else {
            throw NSError(domain: "PhotoService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to data"])
        }
        
        // Create a unique filename
        let filename = "\(shopId)_\(userId)_\(Date().timeIntervalSince1970).jpg"
        let storageRef = storage.reference().child("shop_photos/\(filename)")
        
        // Upload the image
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        let _ = try await storageRef.putDataAsync(imageData, metadata: metadata)
        
        // Get the download URL
        let downloadURL = try await storageRef.downloadURL()
        return downloadURL.absoluteString
    }
    
    func deletePhoto(at url: String) async throws {
        guard let url = URL(string: url) else {
            throw NSError(domain: "PhotoService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        let storageRef = storage.reference(forURL: url.absoluteString)
        try await storageRef.delete()
    }
}

extension UIImage {
    func resized(to size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: size))
        }
    }
} 