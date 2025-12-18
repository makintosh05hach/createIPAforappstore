import SwiftUI

struct FavoritesView: View {
    let viewModel: ServicesViewModel
    let themeManager: ThemeManager
    @State private var showServiceDetail: Service?
    
    var favorites: [Service] {
        viewModel.favorites()
    }
    
    var body: some View {
        let _ = viewModel.services // Force refresh when services change
    
        NavigationStack {
            ZStack {
                themeManager.currentTheme.backgroundColorValue
                    .ignoresSafeArea()
                
                if favorites.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "star")
                            .font(.system(size: 60))
                            .foregroundColor(themeManager.currentTheme.textColorValue.opacity(0.3))
                        
                        Text("No Favorites Yet")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(themeManager.currentTheme.textColorValue)
                        
                        Text("Tap the star icon on any service to add it to favorites")
                            .font(.system(size: 16))
                            .foregroundColor(themeManager.currentTheme.textColorValue.opacity(0.6))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(favorites) { service in
                                Button {
                                    showServiceDetail = service
                                } label: {
                                    FavoriteServiceCard(service: service, viewModel: viewModel, themeManager: themeManager)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(20)
                    }
                }
            }
            .navigationTitle("Favorites")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(themeManager.currentTheme.id == "dark" ? .dark : (themeManager.currentTheme.id == "light" ? .light : nil), for: .navigationBar)
            .sheet(item: $showServiceDetail) { service in
                NavigationStack {
                    ServiceDetailView(
                        service: service,
                        viewModel: viewModel,
                        themeManager: themeManager
                    )
                }
            }
        }
        .onAppear {
            viewModel.loadData()
        }
    }
}

struct FavoriteServiceCard: View {
    let service: Service
    let viewModel: ServicesViewModel
    let themeManager: ThemeManager
    @Environment(AppSettings.self) private var appSettings
    
    var body: some View {
        HStack(spacing: 16) {
            if let photoData = service.photoData,
               let uiImage = UIImage(data: photoData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 80, height: 80)
                    .clipped()
                    .cornerRadius(16)
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(themeManager.currentTheme.accentColorValue.opacity(0.1))
                        .frame(width: 80, height: 80)
                    
                    if let category = service.category {
                        Image(systemName: category.iconName ?? "tag.fill")
                            .font(.system(size: 32))
                            .foregroundColor(Color(hex: category.colorName ?? "4A90E2"))
                    }
                }
            }
            
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(service.name ?? "Unnamed")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(themeManager.currentTheme.textColorValue)
                    
                    Spacer()
                    
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                        .font(.system(size: 16))
                }
                
                if let category = service.category {
                    HStack {
                        Image(systemName: category.iconName ?? "folder")
                            .font(.system(size: 12))
                            .foregroundColor(Color(hex: category.colorName ?? "4A90E2"))
                        Text(category.name ?? "Category")
                            .font(.system(size: 14))
                            .foregroundColor(themeManager.currentTheme.textColorValue.opacity(0.6))
                    }
                }
                
                if let date = service.date {
                    Text(date, style: .date)
                        .font(.system(size: 14))
                        .foregroundColor(themeManager.currentTheme.textColorValue.opacity(0.6))
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(PriceFormatter.format(service.price, currency: service.currency ?? appSettings.currency))
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(themeManager.currentTheme.accentColorValue)
                
                if let category = service.category {
                    let average = viewModel.averagePriceInCategory(category)
                    if average > 0 && service.price < average {
                        Text("Good deal")
                            .font(.system(size: 12))
                            .foregroundColor(.green)
                    }
                }
            }
        }
        .padding()
        .background(themeManager.currentTheme.cardColorValue)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 2)
    }
}
