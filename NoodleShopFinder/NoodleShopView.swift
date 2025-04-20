import SwiftUI

struct NoodleShopView: View {
    let noodleShop: NoodleShop
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Shop Image
            Group {
                if let url = URL(string: noodleShop.photo_url) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .frame(height: 200)
                                .frame(maxWidth: .infinity)
                                .background(Color.gray.opacity(0.1))
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 200)
                                .frame(maxWidth: .infinity)
                                .clipped()
                        case .failure:
                            placeholderImage
                        @unknown default:
                            EmptyView()
                        }
                    }
                } else {
                    placeholderImage
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // Shop Info
            VStack(alignment: .leading, spacing: 4) {
                Text(noodleShop.name)
                    .font(.headline)
                
                Text(noodleShop.address)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
    
    private var placeholderImage: some View {
        Image(systemName: "photo")
            .resizable()
            .scaledToFit()
            .frame(height: 200)
            .frame(maxWidth: .infinity)
            .foregroundColor(.gray)
            .background(Color.gray.opacity(0.1))
    }
}
