import SwiftUI

struct DashboardView: View {
    @Environment(AppSettings.self) private var appSettings
    let viewModel: ServicesViewModel
    let themeManager: ThemeManager
    @State private var showAddService = false
    @State private var showAddCategory = false
    @State private var searchText = ""
    @State private var showSearchView = false
    
    var quickStats: (totalSpent: Double, avgPrice: Double, totalSpentFormatted: String, avgPriceFormatted: String) {
        let totalSpent = viewModel.services.reduce(0) { $0 + $1.price }
        let avgPrice = viewModel.services.isEmpty ? 0 : totalSpent / Double(viewModel.services.count)
        
        return (
            totalSpent: totalSpent,
            avgPrice: avgPrice,
            totalSpentFormatted: PriceFormatter.formatCompact(totalSpent, currency: appSettings.currency),
            avgPriceFormatted: PriceFormatter.formatCompact(avgPrice, currency: appSettings.currency)
        )
    }
    
    var body: some View {
        NavigationStack {
            ThemeView(themeManager: themeManager) { theme in
                ZStack {
                    theme.backgroundColorValue
                        .ignoresSafeArea()
                    
                    VStack(spacing: 0) {
                        // Statistics Header
                        VStack(spacing: 8) {
                            Text("\(viewModel.services.count) services")
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundColor(theme.textColorValue)
                            
                            Text("in \(viewModel.categories.count) categories")
                                .font(.system(size: 16, weight: .regular))
                                .foregroundColor(theme.textColorValue.opacity(0.7))
                            
                            // Quick Stats
                            HStack(spacing: 20) {
                                VStack(spacing: 4) {
                                    Text(quickStats.totalSpentFormatted)
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(theme.accentColorValue)
                                    Text("Total Spent")
                                        .font(.system(size: 12))
                                        .foregroundColor(theme.textColorValue.opacity(0.6))
                                }
                                
                                VStack(spacing: 4) {
                                    Text(quickStats.avgPriceFormatted)
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(theme.accentColorValue)
                                    Text("Average")
                                        .font(.system(size: 12))
                                        .foregroundColor(theme.textColorValue.opacity(0.6))
                                }
                            }
                            .padding(.top, 8)
                        }
                        .padding(.top, 20)
                        .padding(.bottom, 10)
                        
                        // Search Bar
                        Button {
                            showSearchView = true
                        } label: {
                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(.gray)
                                
                                Text("Search services and categories...")
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                            }
                            .padding()
                            .background(theme.cardColorValue)
                            .cornerRadius(16)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                        
                        // Categories List
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(viewModel.categories) { category in
                                    NavigationLink(destination: CategoryDetailView(category: category, viewModel: viewModel, themeManager: themeManager)) {
                                        CategoryCardView(
                                            category: category,
                                            viewModel: viewModel,
                                            theme: theme
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 100)
                        }
                    }
                }
                .navigationTitle("Price List")
                .navigationBarTitleDisplayMode(.large)
                .toolbarColorScheme(theme.id == "dark" ? .dark : (theme.id == "light" ? .light : nil), for: .navigationBar)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            showAddCategory = true
                        } label: {
                            Image(systemName: "folder.badge.plus")
                        }
                    }
                }
            .sheet(isPresented: $showAddService) {
                ServiceFormView(
                    viewModel: viewModel,
                    themeManager: themeManager,
                    service: nil
                )
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        NavigationLink(destination: TemplatesView(viewModel: viewModel, themeManager: themeManager)) {
                            Label("Templates", systemImage: "doc.text.fill")
                        }
                        
                        NavigationLink(destination: RecurringServicesView(viewModel: viewModel, themeManager: themeManager)) {
                            Label("Recurring Services", systemImage: "repeat.circle.fill")
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            }
            .sheet(isPresented: $showAddCategory) {
                CategoryFormView(
                    viewModel: viewModel,
                    themeManager: themeManager,
                    category: nil
                )
            }
            .sheet(isPresented: $showSearchView) {
                SearchView(
                    viewModel: viewModel,
                    themeManager: themeManager,
                    searchText: $searchText
                )
            }
            .overlay(alignment: .bottomTrailing) {
                    Button {
                        showAddService = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 60, height: 60)
                            .background(theme.accentColorValue)
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                    }
                    .padding(20)
                }
            }
        }
        .onAppear {
            viewModel.loadData()
        }
    }
}

struct ThemeView<Content: View>: View {
    @Environment(\.colorScheme) var colorScheme
    let themeManager: ThemeManager
    @ViewBuilder let content: (AppTheme) -> Content
    
    var body: some View {
        content(themeManager.resolvedTheme(colorScheme: colorScheme))
    }
}

struct CategoryCardView: View {
    let category: Category
    let viewModel: ServicesViewModel
    let theme: AppTheme
    @Environment(AppSettings.self) private var appSettings
    
    var body: some View {
        let servicesCount = viewModel.servicesInCategory(category).count
        let averagePrice = viewModel.averagePriceInCategory(category)
        
        HStack(spacing: 16) {
            // Icon
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
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 2)
    }
}

