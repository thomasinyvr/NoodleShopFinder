import SwiftUI
import FirebaseStorage

struct NoodleShopDetailView: View {
    let shop: NoodleShop
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    
                    // Shop Image
                    AsyncImage(url: URL(string: shop.photo_url)) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .frame(height: 200)
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 200)
                                .clipped()
                        case .failure:
                            Image(systemName: "photo")
                                .resizable()
                                .scaledToFit()
                                .frame(height: 200)
                                .foregroundColor(.gray)
                                .background(Color.gray.opacity(0.2))
                        @unknown default:
                            EmptyView()
                        }
                    }

                    // Basic Info
                    VStack(alignment: .leading, spacing: 8) {
                        Text(shop.name)
                            .font(.title)
                            .fontWeight(.bold)

                        Text(shop.address)
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        if let website = shop.website {
                            Link("Visit Website", destination: URL(string: website)!)
                                .font(.subheadline)
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.horizontal)

                    Divider().padding(.horizontal)

                    // Extra Info
                    VStack(alignment: .leading, spacing: 8) {
                        if let rating = shop.rating {
                            Text("Rating: \(rating, specifier: "%.1f") ⭐️")
                        }

                        if let total = shop.user_ratings_total {
                            Text("Based on \(total) reviews")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        if let openNow = shop.current_opening_hours?.open_now {
                            Text(openNow ? "Open Now" : "Closed")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(openNow ? .green : .red)
                        }

                        if let servesBeer = shop.serves_beer, servesBeer {
                            Label("Serves Beer", systemImage: "wineglass")
                        }

                        if let servesBreakfast = shop.serves_breakfast, servesBreakfast {
                            Label("Serves Breakfast", systemImage: "sunrise")
                        }

                        if let hours = shop.current_opening_hours?.weekday_text {
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
                    if let reviews = shop.reviews, !reviews.isEmpty {
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
            .navigationTitle(shop.name)
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
