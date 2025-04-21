import SwiftUI

struct LeaveReviewView: View {
    let noodleShop: NoodleShop
    @Environment(\.dismiss) private var dismiss
    @State private var showingReviewInput = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Share your experience at")
                    .font(.headline)
                
                Text(noodleShop.name)
                    .font(.title2)
                    .bold()
                
                Text("Your review will be visible to other users")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                Button(action: { showingReviewInput = true }) {
                    HStack {
                        Image(systemName: "star.fill")
                        Text("Write a Review")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange)
                    .cornerRadius(10)
                }
                .padding(.horizontal)
            }
            .padding()
            .navigationTitle("Leave a Review")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingReviewInput) {
                ReviewInputView(
                    title: "Write a Review",
                    isPublic: true
                ) { content in
                    // TODO: Save review to Firestore
                    print("Saving public review:", content)
                }
            }
        }
    }
}

#Preview {
    LeaveReviewView(noodleShop: NoodleShop(
        id: "1",
        name: "Sample Noodle Shop",
        lat: 49.2827,
        lng: -123.1207
    ))
} 