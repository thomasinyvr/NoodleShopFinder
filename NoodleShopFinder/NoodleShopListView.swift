import SwiftUI

struct NoodleShopListView: View {
    @ObservedObject var viewModel: NoodleShopViewModel
    @State private var searchText = ""
    
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
            List(filteredShops) { shop in
                NavigationLink(destination: NoodleShopDetailView(noodleShop: shop)) {
                    HStack(spacing: 16) {
                        // Shop Image
                        AsyncImage(url: URL(string: shop.photo_url)) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                                    .frame(width: 100, height: 100)
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 100, height: 100)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            case .failure:
                                Image(systemName: "photo")
                                    .frame(width: 100, height: 100)
                                    .background(Color.gray.opacity(0.2))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            @unknown default:
                                EmptyView()
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text(shop.name)
                                .font(.headline)
                                .lineLimit(2)
                            Text(shop.address)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("Noodle Shops")
            .searchable(text: $searchText, prompt: "Search shops")
        }
    }
}
