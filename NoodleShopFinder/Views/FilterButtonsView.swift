import SwiftUI

struct FilterButtonsView: View {
    @ObservedObject var viewModel: NoodleShopViewModel
    @Binding var isShowingListView: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // Filter Buttons
            FilterButton(
                systemImage: "wineglass",
                isActive: $viewModel.showServesBeer,
                color: .blue
            )
            
            FilterButton(
                systemImage: "clock",
                isActive: $viewModel.showOpenNow,
                color: .green
            )
            
            Menu {
                Button(action: {
                    viewModel.minRating = 4.5
                    viewModel.sortByRating = true
                }) {
                    Label("4.5+ Stars", systemImage: "star.fill")
                }
                
                Button(action: {
                    viewModel.minRating = 4.0
                    viewModel.sortByRating = true
                }) {
                    Label("4.0+ Stars", systemImage: "star.fill")
                }
                
                Button(action: {
                    viewModel.minRating = 3.5
                    viewModel.sortByRating = true
                }) {
                    Label("3.5+ Stars", systemImage: "star.fill")
                }
                
                Button(action: {
                    viewModel.minRating = 3.0
                    viewModel.sortByRating = true
                }) {
                    Label("3.0+ Stars", systemImage: "star.fill")
                }
                
                Divider()
                
                Button(action: {
                    viewModel.sortByRating = false
                }) {
                    Label("Show All", systemImage: "star")
                }
            } label: {
                Image(systemName: viewModel.sortByRating ? "star.fill" : "star")
                    .font(.title2)
                    .padding(8)
                    .background(viewModel.sortByRating ? Color.yellow.opacity(0.2) : Color.white)
                    .foregroundColor(viewModel.sortByRating ? .yellow : .primary)
                    .clipShape(Circle())
                    .shadow(radius: 2)
            }
            
            // Toggle Button
            Button(action: {
                isShowingListView.toggle()
            }) {
                Image(systemName: isShowingListView ? "map.fill" : "list.bullet")
                    .font(.title2)
                    .padding(8)
                    .background(Color.white)
                    .clipShape(Circle())
                    .shadow(radius: 2)
            }
        }
        .padding()
    }
} 