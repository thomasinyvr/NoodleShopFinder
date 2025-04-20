import SwiftUI

struct NoodleShopListView: View {
    @ObservedObject var viewModel: NoodleShopViewModel
    @State private var searchText = ""
    
    var filteredShops: [NoodleShop] {
        if searchText.isEmpty {
            return viewModel.filteredShops
        } else {
            return viewModel.filteredShops.filter { shop in
                shop.name.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        List(filteredShops) { shop in
            NavigationLink(destination: NoodleShopDetailView(shop: shop)) {
                HStack {
                    if let photoURL = shop.photo_url {
                        AsyncImage(url: URL(string: photoURL)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Color.gray.opacity(0.2)
                        }
                        .frame(width: 60, height: 60)
                        .cornerRadius(8)
                    } else {
                        Color.gray.opacity(0.2)
                            .frame(width: 60, height: 60)
                            .cornerRadius(8)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(shop.name)
                            .font(.headline)
                        
                        HStack {
                            if let rating = shop.rating {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.yellow)
                                Text(String(format: "%.1f", rating))
                            }
                            
                            if let servesBeer = shop.serves_beer, servesBeer {
                                Image(systemName: "wineglass")
                                    .foregroundColor(.blue)
                            }
                            
                            if let openNow = shop.current_opening_hours?.open_now, openNow {
                                Image(systemName: "clock")
                                    .foregroundColor(.green)
                            }
                        }
                        .font(.subheadline)
                        
                        Text(shop.vicinity)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .searchable(text: $searchText, prompt: "Search noodle shops")
        .navigationTitle("Noodle Shops")
    }
}
