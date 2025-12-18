import SwiftUI

struct SearchView: View {
    let viewModel: ServicesViewModel
    let themeManager: ThemeManager
    @Binding var searchText: String
    @Environment(\.dismiss) private var dismiss
    @State private var showServiceDetail: Service?
    @State private var showCategoryDetail: Category?
    @FocusState private var isSearchFocused: Bool
    
    var filteredCategories: [Category] {
        if searchText.isEmpty {
            return []
        }
        
        return viewModel.categories.filter { category in
            category.name?.localizedCaseInsensitiveContains(searchText) ?? false
        }
    }
    
    var filteredServices: [Service] {
        if searchText.isEmpty {
            return []
        }
        
        return viewModel.services.filter { service in
            (service.name?.localizedCaseInsensitiveContains(searchText) ?? false) ||
            (service.provider?.localizedCaseInsensitiveContains(searchText) ?? false) ||
            (service.note?.localizedCaseInsensitiveContains(searchText) ?? false) ||
            (service.location?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }
    
    var body: some View {
        ThemeView(themeManager: themeManager) { theme in
            NavigationStack {
                VStack(spacing: 0) {
                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        
                        TextField("Search services and categories...", text: $searchText)
                            .textFieldStyle(.plain)
                            .focused($isSearchFocused)
                            .autocorrectionDisabled()
                    }
                    .padding()
                    .background(theme.cardColorValue)
                    .cornerRadius(16)
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    .padding(.bottom, 20)
                    
                    ZStack {
                        theme.backgroundColorValue
                            .ignoresSafeArea()
                        
                        if searchText.isEmpty {
                            VStack(spacing: 20) {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 60))
                                    .foregroundColor(theme.textColorValue.opacity(0.3))
                                
                                Text("Start typing to search")
                                    .font(.system(size: 24, weight: .semibold))
                                    .foregroundColor(theme.textColorValue)
                                
                                Text("Search for services, categories, providers, and more")
                                    .font(.system(size: 16))
                                    .foregroundColor(theme.textColorValue.opacity(0.6))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 40)
                            }
                        } else if filteredCategories.isEmpty && filteredServices.isEmpty {
                            VStack(spacing: 20) {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 60))
                                    .foregroundColor(theme.textColorValue.opacity(0.3))
                                
                                Text("No Results Found")
                                    .font(.system(size: 24, weight: .semibold))
                                    .foregroundColor(theme.textColorValue)
                                
                                Text("Try a different search term")
                                    .font(.system(size: 16))
                                    .foregroundColor(theme.textColorValue.opacity(0.6))
                            }
                        } else {
                            ScrollView {
                                VStack(alignment: .leading, spacing: 24) {
                                    // Categories Section
                                    if !filteredCategories.isEmpty {
                                        VStack(alignment: .leading, spacing: 12) {
                                            Text("Categories")
                                                .font(.system(size: 20, weight: .bold))
                                                .foregroundColor(theme.textColorValue)
                                                .padding(.horizontal, 20)
                                            
                                            ForEach(filteredCategories) { category in
                                                Button {
                                                    showCategoryDetail = category
                                                } label: {
                                                    SearchCategoryCard(category: category, viewModel: viewModel, theme: theme)
                                                }
                                                .buttonStyle(.plain)
                                            }
                                        }
                                    }
                                    
                                    // Services Section
                                    if !filteredServices.isEmpty {
                                        VStack(alignment: .leading, spacing: 12) {
                                            Text("Services")
                                                .font(.system(size: 20, weight: .bold))
                                                .foregroundColor(theme.textColorValue)
                                                .padding(.horizontal, 20)
                                            
                                            ForEach(filteredServices) { service in
                                                Button {
                                                    showServiceDetail = service
                                                } label: {
                                                    SearchServiceCard(service: service, theme: theme)
                                                }
                                                .buttonStyle(.plain)
                                            }
                                        }
                                    }
                                }
                                .padding(.vertical, 20)
                            }
                        }
                    }
                }
                .navigationTitle("Search")
                .onAppear {
                    isSearchFocused = true
                }
                .navigationBarTitleDisplayMode(.large)
                .toolbarColorScheme(theme.id == "dark" ? .dark : (theme.id == "light" ? .light : nil), for: .navigationBar)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
                .sheet(item: $showServiceDetail) { service in
                    NavigationStack {
                        ServiceDetailView(
                            service: service,
                            viewModel: viewModel,
                            themeManager: themeManager
                        )
                    }
                }
                .sheet(item: $showCategoryDetail) { category in
                    NavigationStack {
                        CategoryDetailView(
                            category: category,
                            viewModel: viewModel,
                            themeManager: themeManager
                        )
                    }
                }
            }
        }
    }
}

struct SearchCategoryCard: View {
    let category: Category
    let viewModel: ServicesViewModel
    let theme: AppTheme
    @Environment(AppSettings.self) private var appSettings
    
    var body: some View {
        let servicesCount = viewModel.servicesInCategory(category).count
        let averagePrice = viewModel.averagePriceInCategory(category)
        
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color(hex: category.colorName ?? "4A90E2").opacity(0.2))
                    .frame(width: 60, height: 60)
                
                Image(systemName: category.iconName ?? "folder.fill")
                    .font(.system(size: 24))
                    .foregroundColor(Color(hex: category.colorName ?? "4A90E2"))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(category.name ?? "Unnamed")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(theme.textColorValue)
                
                Text("\(servicesCount) services")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(theme.textColorValue.opacity(0.6))
                
                if averagePrice > 0 {
                    Text(PriceFormatter.formatCompact(averagePrice, currency: appSettings.currency))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(theme.accentColorValue)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding()
        .background(theme.cardColorValue)
        .cornerRadius(20)
        .padding(.horizontal, 20)
    }
}

struct SearchServiceCard: View {
    let service: Service
    let theme: AppTheme
    @Environment(AppSettings.self) private var appSettings
    
    var body: some View {
        HStack(spacing: 16) {
            if let category = service.category {
                ZStack {
                    Circle()
                        .fill(Color(hex: category.colorName ?? "4A90E2").opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: category.iconName ?? "folder.fill")
                        .font(.system(size: 20))
                        .foregroundColor(Color(hex: category.colorName ?? "4A90E2"))
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(service.name ?? "Unnamed")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(theme.textColorValue)
                
                if let category = service.category {
                    Text(category.name ?? "Category")
                        .font(.system(size: 14))
                        .foregroundColor(theme.textColorValue.opacity(0.6))
                }
                
                if let provider = service.provider {
                    Text(provider)
                        .font(.system(size: 14))
                        .foregroundColor(theme.textColorValue.opacity(0.6))
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(PriceFormatter.format(service.price, currency: service.currency ?? appSettings.currency))
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(theme.accentColorValue)
                
                if let date = service.date {
                    Text(date, style: .date)
                        .font(.system(size: 12))
                        .foregroundColor(theme.textColorValue.opacity(0.5))
                }
            }
        }
        .padding()
        .background(theme.cardColorValue)
        .cornerRadius(16)
        .padding(.horizontal, 20)
    }
}
