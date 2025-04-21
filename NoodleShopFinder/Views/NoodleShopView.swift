import SwiftUI

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("Search", text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
    }
}

struct NoodleShopView: View {
    @ObservedObject var viewModel: NoodleShopViewModel
    @State private var selectedShop: NoodleShop?
    @State private var showingDetail = false
    @State private var searchText = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var debugInfo: String = ""
    
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
                print("🔗 Generated URL with photo reference: \(urlString)")
                return URL(string: urlString)
            }
            print("🔗 Using direct photo URL: \(shop.photo_url)")
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
        
        print("🌐 Final URL being used: \(photoURL.absoluteString)")
        
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
    
    var filteredShops: [NoodleShop] {
        if searchText.isEmpty {
            return viewModel.noodleShops
        } else {
            return viewModel.noodleShops.filter { shop in
                shop.name.localizedCaseInsensitiveContains(searchText) ||
                shop.address.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                SearchBar(text: $searchText)
                    .padding(.horizontal, 16)
                
                if !debugInfo.isEmpty {
                    ScrollView {
                        Text(debugInfo)
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                            .padding(.horizontal)
                    }
                    .frame(maxHeight: 100)
                }
                
                List(filteredShops) { shop in
                    Button(action: {
                        selectedShop = shop
                        showingDetail = true
                        print("Selected Shop: \(shop.name)")
                        print("Photo URL: \(shop.photo_url)")
                        debugInfo = "Selected Shop: \(shop.name)\nPhoto URL: \(shop.photo_url)"
                    }) {
                        HStack {
                            loadImage(for: shop)
                            
                            VStack(alignment: .leading) {
                                Text(shop.name)
                                    .font(.headline)
                                Text(shop.address)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
                .listStyle(PlainListStyle())
            }
            .navigationTitle("Noodle Shops")
            .sheet(isPresented: $showingDetail) {
                if let shop = selectedShop {
                    NoodleShopDetailView(noodleShop: shop)
                }
            }
        }
    }
}
