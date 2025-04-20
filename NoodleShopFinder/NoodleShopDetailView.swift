import SwiftUI
import FirebaseStorage
import Foundation

struct NoodleShopDetailView: View {
    let noodleShop: NoodleShop
    @Environment(\.dismiss) private var dismiss
    @State private var retryCount = 0
    @State private var isLoading = true
    @State private var error: Error?
    @State private var debugInfo: String = ""
    
    private let maxRetries = 3
    
    private func loadImage(for shop: NoodleShop) -> AnyView {
        print("🔍 Loading image for shop: \(shop.name)")
        print("📸 Photo URL: \(shop.photo_url)")
        print("📸 Photo Reference: \(shop.photo_reference ?? "none")")
        print("🔑 Using API key: \(Bundle.main.object(forInfoDictionaryKey: "GMSPlacesClientAPIKey") as? String ?? "default")")
        
        // If we have a photo reference, use it to generate the URL
        let imageURL: URL? = {
            if let photoReference = shop.photo_reference {
                let apiKey = Bundle.main.object(forInfoDictionaryKey: "GMSPlacesClientAPIKey") as? String ?? "AIzaSyAYc5_1r_ExFfZn2F0s58LREqS3D2ixLr0"
                let urlString = "https://maps.googleapis.com/maps/api/place/photo?maxwidth=800&photo_reference=\(photoReference)&key=\(apiKey)"
                return URL(string: urlString)
            }
            return URL(string: shop.photo_url)
        }()
        
        guard let photoURL = imageURL else {
            print("❌ Invalid URL format")
            return AnyView(
                Image(systemName: "photo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
                    .frame(width: 50, height: 50)
            )
        }
        
        return AnyView(
            AsyncImage(url: photoURL) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .frame(width: 50, height: 50)
                        .onAppear {
                            print("⏳ Loading image for \(shop.name)")
                            print("🌐 Request URL: \(photoURL.absoluteString)")
                        }
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: 50, height: 50)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .onAppear {
                            print("✅ Successfully loaded image for \(shop.name)")
                            print("📡 Response URL: \(photoURL.absoluteString)")
                            debugInfo = "Successfully loaded image for \(shop.name)"
                        }
                case .failure(let error):
                    VStack {
                        Image(systemName: "photo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 30, height: 30)
                        Text("Error")
                            .font(.caption)
                    }
                    .frame(width: 50, height: 50)
                    .onAppear {
                        print("❌ Image loading failed for \(shop.name):")
                        print("   - Error: \(error.localizedDescription)")
                        if let urlError = error as? URLError {
                            print("   - Code: \(urlError.code)")
                            print("   - Description: \(urlError.localizedDescription)")
                            print("   - Failing URL: \(urlError.failingURL?.absoluteString ?? "unknown")")
                            print("   - Network Unavailable: \(urlError.code == .notConnectedToInternet)")
                            print("   - Network Connection Lost: \(urlError.code == .networkConnectionLost)")
                            print("   - Timed Out: \(urlError.code == .timedOut)")
                            print("   - Bad Server Response: \(urlError.code == .badServerResponse)")
                        }
                        debugInfo = "Image Error: \(error.localizedDescription)"
                    }
                @unknown default:
                    EmptyView()
                }
            }
        )
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let error = error {
                        VStack {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.largeTitle)
                                .foregroundColor(.red)
                            Text("Failed to load image")
                                .font(.headline)
                            Text(error.localizedDescription)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            if retryCount < maxRetries {
                                Button("Retry") {
                                    retryCount += 1
                                    self.error = nil
                                    self.isLoading = true
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                        .frame(height: 200)
                        .frame(maxWidth: .infinity)
                        .background(Color.gray.opacity(0.1))
                    } else {
                        loadImage(for: noodleShop)
                            .frame(height: 200)
                            .frame(maxWidth: .infinity)
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text(noodleShop.name)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        if let rating = noodleShop.rating {
                            HStack {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.yellow)
                                Text(String(format: "%.1f", rating))
                                    .font(.headline)
                            }
                        }
                        
                        Text(noodleShop.address)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        if let servesBeer = noodleShop.serves_beer, servesBeer {
                            Label("Serves Beer", systemImage: "wineglass")
                                .foregroundColor(.blue)
                        }
                        
                        if let openNow = noodleShop.current_opening_hours?.open_now {
                            Label(openNow ? "Open Now" : "Closed", 
                                  systemImage: openNow ? "clock.fill" : "clock")
                                .foregroundColor(openNow ? .green : .red)
                        }
                    }
                    .padding()

                    // Extra Info
                    VStack(alignment: .leading, spacing: 8) {
                        if let total = noodleShop.user_ratings_total {
                            Text("Based on \(total) reviews")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        if let hours = noodleShop.current_opening_hours?.weekday_text {
                            Divider().padding(.vertical, 4)
                            Text("Hours:")
                                .font(.headline)
                            ForEach(hours, id: \.self) { day in
                                Text(day)
                                    .font(.caption)
                            }
                        }
                    }
                    .padding(.horizontal)

                    // Reviews
                    if let reviews = noodleShop.reviews, !reviews.isEmpty {
                        Divider().padding(.horizontal)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Reviews")
                                .font(.headline)
                            
                            ForEach(reviews.prefix(3), id: \.author_name) { review in
                                VStack(alignment: .leading, spacing: 4) {
                                    if let author = review.author_name {
                                        Text(author).bold()
                                    }

                                    if let rating = review.rating {
                                        Text("Rating: \(rating, specifier: "%.1f")")
                                            .font(.subheadline)
                                    }

                                    if let text = review.text {
                                        Text(text)
                                            .font(.body)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .navigationTitle(noodleShop.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
