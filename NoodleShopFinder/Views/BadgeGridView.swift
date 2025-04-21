import SwiftUI

struct BadgeGridView: View {
    @StateObject private var service = BadgeProgressService.shared
    let userId = "demo_user_123" // Replace with actual auth ID later
    
    private let columns = [
        GridItem(.adaptive(minimum: 150), spacing: 20)
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(BadgeCatalog.all) { badge in
                        let progress = service.progressList.first { $0.id == badge.id }
                        BadgeView(badge: badge, progress: progress, size: 80)
                    }
                }
                .padding()
            }
            .navigationTitle("My Badges")
            .onAppear {
                service.fetchBadgeProgress(for: userId)
            }
        }
    }
}

#Preview {
    BadgeGridView()
}
