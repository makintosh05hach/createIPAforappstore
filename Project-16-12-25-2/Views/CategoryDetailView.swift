import SwiftUI
import Charts

struct CategoryDetailView: View {
    let category: Category
    let viewModel: ServicesViewModel
    let themeManager: ThemeManager
    @Environment(AppSettings.self) private var appSettings
    @State private var sortOption: SortOption = .date
    @State private var showServiceDetail: Service?
    @State private var showAddService = false
    
    enum SortOption: String, CaseIterable, Hashable {
        case price = "Price"
        case date = "Date"
        case name = "Name"
    }
    
    var services: [Service] {
        let categoryServices = viewModel.servicesInCategory(category)
        switch sortOption {
        case .price:
            return categoryServices.sorted { $0.price < $1.price }
        case .date:
            return categoryServices.sorted { ($0.date ?? Date()) > ($1.date ?? Date()) }
        case .name:
            return categoryServices.sorted { ($0.name ?? "") < ($1.name ?? "") }
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Statistics
                HStack(spacing: 20) {
                    StatCard(
                        title: "Average",
                        value: PriceFormatter.formatCompact(viewModel.averagePriceInCategory(category), currency: appSettings.currency),
                        themeManager: themeManager
                    )
                    
                    StatCard(
                        title: "Min",
                        value: PriceFormatter.formatCompact(viewModel.minPriceInCategory(category), currency: appSettings.currency),
                        themeManager: themeManager
                    )
                    
                    StatCard(
                        title: "Max",
                        value: PriceFormatter.formatCompact(viewModel.maxPriceInCategory(category), currency: appSettings.currency),
                        themeManager: themeManager
                    )
                }
                .padding(.horizontal, 20)
                
                // Chart
                if services.count >= 2 {
                    let validServices = services.filter { $0.price >= 0 }
                    if !validServices.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Price Trend")
                                .font(.system(size: 20, weight: .semibold))
                                .padding(.horizontal, 20)
                            
                            Chart {
                                ForEach(Array(validServices.enumerated()), id: \.element.id) { index, service in
                                    LineMark(
                                        x: .value("Index", index),
                                        y: .value("Price", service.price)
                                    )
                                    .foregroundStyle(themeManager.currentTheme.accentColorValue)
                                    .interpolationMethod(.catmullRom)
                                    
                                    AreaMark(
                                        x: .value("Index", index),
                                        y: .value("Price", service.price)
                                    )
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [
                                                themeManager.currentTheme.accentColorValue.opacity(0.3),
                                                themeManager.currentTheme.accentColorValue.opacity(0.0)
                                            ],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .interpolationMethod(.catmullRom)
                                }
                            }
                            .frame(height: 200)
                            .padding()
                            .background(themeManager.currentTheme.cardColorValue)
                            .cornerRadius(20)
                            .padding(.horizontal, 20)
                        }
                    }
                }
                
                // Sort Picker
                Picker("Sort", selection: $sortOption) {
                    ForEach(SortOption.allCases, id: \.self) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 20)
                
                // Services List
                LazyVStack(spacing: 12) {
                    ForEach(services) { service in
                        Button {
                            showServiceDetail = service
                        } label: {
                            ServiceRowView(service: service, themeManager: themeManager)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .padding(.vertical, 20)
        }
        .background(themeManager.currentTheme.backgroundColorValue)
        .navigationTitle(category.name ?? "Category")
        .navigationBarTitleDisplayMode(.large)
        .toolbarColorScheme(themeManager.currentTheme.id == "dark" ? .dark : (themeManager.currentTheme.id == "light" ? .light : nil), for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showAddService = true
                } label: {
                    Image(systemName: "plus")
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
        .sheet(isPresented: $showAddService) {
            ServiceFormView(
                viewModel: viewModel,
                themeManager: themeManager,
                service: nil,
                preselectedCategory: category
            )
        }
    }
    
    private func formatPrice(_ price: Double, currency: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: price)) ?? "$\(Int(price))"
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let themeManager: ThemeManager
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(themeManager.currentTheme.textColorValue.opacity(0.7))
            
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(themeManager.currentTheme.accentColorValue)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(themeManager.currentTheme.cardColorValue)
        .cornerRadius(16)
    }
}

struct ServiceRowView: View {
    let service: Service
    let themeManager: ThemeManager
    @Environment(AppSettings.self) private var appSettings
    
    var body: some View {
        HStack(spacing: 16) {
            if let photoData = service.photoData,
               let uiImage = UIImage(data: photoData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 60, height: 60)
                    .clipped()
                    .cornerRadius(12)
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(themeManager.currentTheme.accentColorValue.opacity(0.1))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: "tag.fill")
                            .foregroundColor(themeManager.currentTheme.accentColorValue)
                    )
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(service.name ?? "Unnamed")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(themeManager.currentTheme.textColorValue)
                
                if let date = service.date {
                    Text(date, style: .date)
                        .font(.system(size: 14))
                        .foregroundColor(themeManager.currentTheme.textColorValue.opacity(0.6))
                }
            }
            
            Spacer()
            
            Text(PriceFormatter.format(service.price, currency: service.currency ?? appSettings.currency))
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(themeManager.currentTheme.accentColorValue)
        }
        .padding()
        .background(themeManager.currentTheme.cardColorValue)
        .cornerRadius(16)
    }
}

