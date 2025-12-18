import SwiftUI

struct HistoryView: View {
    let viewModel: ServicesViewModel
    let themeManager: ThemeManager
    @State private var selectedCategory: Category?
    @State private var dateFrom: Date = Calendar.current.date(byAdding: .month, value: -3, to: Date()) ?? Date()
    @State private var dateTo: Date = Date()
    @State private var minPrice: String = ""
    @State private var maxPrice: String = ""
    @State private var showFilters = false
    @State private var showServiceDetail: Service?
    
    var filteredServices: [Service] {
        var services = viewModel.services
        
        // Only apply filters if they are active
        if showFilters {
            if let category = selectedCategory {
                services = services.filter { $0.category == category }
            }
            
            services = services.filter { service in
                guard let date = service.date else { return true }
                // Make sure dateFrom <= dateTo
                let from = min(dateFrom, dateTo)
                let to = max(dateFrom, dateTo)
                return date >= from && date <= to
            }
            
            if let min = Double(minPrice), min > 0 {
                services = services.filter { $0.price >= min }
            }
            
            if let max = Double(maxPrice), max > 0 {
                services = services.filter { $0.price <= max }
            }
        }
        
        return services.sorted { ($0.date ?? Date()) > ($1.date ?? Date()) }
    }
    
    var body: some View {
        let _ = viewModel.services // Force refresh when services change
        
        NavigationStack {
            ZStack {
                themeManager.currentTheme.backgroundColorValue
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Filters Bar
                    if showFilters {
                        VStack(spacing: 12) {
                            Picker("Category", selection: $selectedCategory) {
                                Text("All Categories").tag(nil as Category?)
                                ForEach(viewModel.categories) { category in
                                    Text(category.name ?? "Unnamed").tag(category as Category?)
                                }
                            }
                            
                            HStack {
                                DatePicker("From", selection: $dateFrom, displayedComponents: .date)
                                DatePicker("To", selection: $dateTo, displayedComponents: .date)
                            }
                            
                            HStack {
                                TextField("Min price", text: $minPrice)
                                    .keyboardType(.decimalPad)
                                TextField("Max price", text: $maxPrice)
                                    .keyboardType(.decimalPad)
                            }
                        }
                        .padding()
                        .background(themeManager.currentTheme.cardColorValue)
                        .cornerRadius(16)
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                    }
                    
                    // Services List
                    if filteredServices.isEmpty {
                        Spacer()
                        VStack(spacing: 20) {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.system(size: 60))
                                .foregroundColor(themeManager.currentTheme.textColorValue.opacity(0.3))
                            
                            Text("No Services Found")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(themeManager.currentTheme.textColorValue)
                            
                            Text("Try adjusting your filters")
                                .font(.system(size: 16))
                                .foregroundColor(themeManager.currentTheme.textColorValue.opacity(0.6))
                        }
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(groupedByDate, id: \.key) { dateGroup in
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text(formatDate(dateGroup.key))
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(themeManager.currentTheme.textColorValue.opacity(0.7))
                                            .padding(.horizontal, 20)
                                            .padding(.top, 16)
                                        
                                        ForEach(dateGroup.value) { service in
                                            Button {
                                                showServiceDetail = service
                                            } label: {
                                                HistoryServiceRow(service: service, themeManager: themeManager)
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                }
                            }
                            .padding(.bottom, 20)
                        }
                    }
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(themeManager.currentTheme.id == "dark" ? .dark : (themeManager.currentTheme.id == "light" ? .light : nil), for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        withAnimation {
                            showFilters.toggle()
                        }
                    } label: {
                        Image(systemName: showFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
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
        }
        .onAppear {
            viewModel.loadData()
        }
    }
    
    private var groupedByDate: [(key: Date, value: [Service])] {
        let grouped = Dictionary(grouping: filteredServices) { service in
            Calendar.current.startOfDay(for: service.date ?? Date())
        }
        return grouped.sorted { $0.key > $1.key }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

struct HistoryServiceRow: View {
    let service: Service
    let themeManager: ThemeManager
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
                    .foregroundColor(themeManager.currentTheme.textColorValue)
                
                if let provider = service.provider {
                    Text(provider)
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
        .padding(.horizontal, 20)
    }
}
