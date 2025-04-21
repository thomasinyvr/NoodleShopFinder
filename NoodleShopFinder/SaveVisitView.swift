import SwiftUI

struct SaveVisitView: View {
    let noodleShop: NoodleShop
    @Environment(\.dismiss) private var dismiss
    @State private var showingVisitInput = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Save your visit to")
                    .font(.headline)
                
                Text(noodleShop.name)
                    .font(.title2)
                    .bold()
                
                Text("Your notes will be private")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                Button(action: { showingVisitInput = true }) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Save Visit")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
                }
                .padding(.horizontal)
            }
            .padding()
            .navigationTitle("Save Visit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingVisitInput) {
                ReviewInputView(
                    title: "Save Visit",
                    isPublic: false
                ) { content in
                    // TODO: Save visit to Firestore
                    print("Saving private visit:", content)
                }
            }
        }
    }
}

#Preview {
    SaveVisitView(noodleShop: NoodleShop(
        id: "1",
        name: "Sample Noodle Shop",
        lat: 49.2827,
        lng: -123.1207
    ))
} 