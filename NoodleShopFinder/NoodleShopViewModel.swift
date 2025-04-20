import SwiftUI
import FirebaseFirestore

class NoodleShopViewModel: ObservableObject {
    @Published var noodleShops: [NoodleShop] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Filter states
    @Published var showServesBeer = false
    @Published var showOpenNow = false
    @Published var sortByRating = false
    @Published var minRating: Double = 4.0
    
    var filteredShops: [NoodleShop] {
        var shops = noodleShops
        
        // Apply filters
        if showServesBeer {
            shops = shops.filter { $0.serves_beer == true }
        }
        
        if showOpenNow {
            shops = shops.filter { $0.current_opening_hours?.open_now == true }
        }
        
        // Filter by minimum rating
        shops = shops.filter { ($0.rating ?? 0) >= minRating }
        
        // Apply sorting
        if sortByRating {
            shops.sort { ($0.rating ?? 0) > ($1.rating ?? 0) }
        }
        
        return shops
    }
    
    private let db = Firestore.firestore()

    init() {
        loadNoodleShops()
    }

    func loadNoodleShops() {
        isLoading = true
        errorMessage = nil

        print("🔍 Fetching noodle shops from Firestore...")

        db.collection("noodle_shops").getDocuments(source: .default) { [weak self] snapshot, error in
            let workItem = DispatchWorkItem { [weak self] in
                guard let self = self else { return }
                
                self.isLoading = false
                
                if let error = error {
                    print("❌ Error fetching documents: \(error.localizedDescription)")
                    self.errorMessage = "Failed to load noodle shops: \(error.localizedDescription)"
                    return
                }
                
                guard let snapshot = snapshot else {
                    print("❌ No snapshot returned from Firestore")
                    self.errorMessage = "No data received from server"
                    return
                }
                
                print("✅ Successfully fetched \(snapshot.documents.count) documents")
                
                self.noodleShops = snapshot.documents.compactMap { doc in
                    let data = doc.data()
                    print("📄 Document data: \(data)")
                    
                    // Parse reviews if they exist
                    let reviews: [Review]? = (data["reviews"] as? [[String: Any]])?.compactMap { reviewData in
                        guard let authorName = reviewData["author_name"] as? String,
                              let rating = reviewData["rating"] as? Double,
                              let text = reviewData["text"] as? String,
                              let time = reviewData["time"] as? Int else {
                            return nil
                        }
                        return Review(
                            author_name: authorName,
                            rating: rating,
                            text: text,
                            time: time,
                            profile_photo_url: reviewData["profile_photo_url"] as? String
                        )
                    }
                    
                    // Parse opening hours if they exist
                    let openingHours: CurrentOpeningHours? = {
                        guard let hoursData = data["current_opening_hours"] as? [String: Any],
                              let openNow = hoursData["open_now"] as? Bool,
                              let periodsData = hoursData["periods"] as? [[String: Any]],
                              let weekdayText = hoursData["weekday_text"] as? [String] else {
                            return nil
                        }
                        
                        let periods = periodsData.compactMap { periodData -> OpeningPeriod? in
                            guard let openData = periodData["open"] as? [String: Any],
                                  let closeData = periodData["close"] as? [String: Any],
                                  let openTime = self.parseOpeningTime(openData),
                                  let closeTime = self.parseOpeningTime(closeData) else {
                                return nil
                            }
                            return OpeningPeriod(open: openTime, close: closeTime)
                        }
                        
                        return CurrentOpeningHours(
                            open_now: openNow,
                            periods: periods,
                            weekday_text: weekdayText
                        )
                    }()
                    
                    let shop = NoodleShop(
                        id: doc.documentID,
                        name: data["name"] as? String ?? "Unknown",
                        lat: data["lat"] as? Double ?? 0.0,
                        lng: data["lng"] as? Double ?? 0.0,
                        address: data["address"] as? String ?? "No address available",
                        photo_url: data["photo_url"] as? String ?? "",
                        website: data["website"] as? String,
                        rating: data["rating"] as? Double,
                        price_level: data["price_level"] as? Int,
                        user_ratings_total: data["user_ratings_total"] as? Int,
                        current_opening_hours: openingHours,
                        reviews: reviews,
                        serves_beer: data["serves_beer"] as? Bool,
                        serves_breakfast: data["serves_breakfast"] as? Bool
                    )
                    
                    print("🏪 Created shop: \(shop.name) with photo URL: \(shop.photo_url)")
                    return shop
                }
            }
            
            DispatchQueue.main.async(execute: workItem)
        }
    }
    
    private func parseOpeningTime(_ data: [String: Any]) -> OpeningTime? {
        guard let date = data["date"] as? String,
              let day = data["day"] as? Int,
              let time = data["time"] as? String else {
            return nil
        }
        return OpeningTime(date: date, day: day, time: time)
    }
}
