import SwiftUI
import MapKit
import FirebaseFirestore

struct ContentView: View {
    @StateObject private var viewModel = NoodleShopViewModel()
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 49.2827, longitude: -123.1207),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    @State private var selectedShop: NoodleShop?
    @State private var isShowingListView = false
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .topTrailing) {
                if isShowingListView {
                    NoodleShopListView(viewModel: viewModel)
                } else {
                    Map(coordinateRegion: $region, annotationItems: viewModel.filteredShops) { shop in
                        MapAnnotation(coordinate: CLLocationCoordinate2D(
                            latitude: shop.lat,
                            longitude: shop.lng
                        )) {
                            VStack {
                                Image(systemName: "mappin.circle.fill")
                                    .font(.title)
                                    .foregroundColor(.red)
                                    .onTapGesture {
                                        selectedShop = shop
                                    }
                                
                                if selectedShop?.id == shop.id {
                                    Text(shop.name)
                                        .font(.caption)
                                        .padding(4)
                                        .background(Color.white)
                                        .cornerRadius(4)
                                        .shadow(radius: 2)
                                }
                            }
                        }
                    }
                    .ignoresSafeArea()
                    .sheet(item: $selectedShop) { shop in
                        NoodleShopDetailView(noodleShop: shop)
                    }
                }
                
                FilterButtonsView(viewModel: viewModel, isShowingListView: $isShowingListView)
            }
        }
    }
}

struct FilterButton: View {
    let systemImage: String
    @Binding var isActive: Bool
    let color: Color
    
    var body: some View {
        Button(action: {
            isActive.toggle()
        }) {
            Image(systemName: systemImage)
                .font(.title2)
                .padding(8)
                .background(isActive ? color.opacity(0.2) : Color.white)
                .foregroundColor(isActive ? color : .primary)
                .clipShape(Circle())
                .shadow(radius: 2)
        }
    }
}

#Preview {
    ContentView()
}




