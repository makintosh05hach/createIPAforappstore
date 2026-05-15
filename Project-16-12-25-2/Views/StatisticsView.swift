import SwiftUI
import Charts

struct StatisticsView: View {
    let viewModel: ServicesViewModel
    let themeManager: ThemeManager
    @Environment(AppSettings.self) private var appSettings
    @State private var selectedPeriod: Period = .month
    
    enum Period: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case year = "Year"
        case all = "All Time"
    }
    
    var filteredServices: [Service] {
        let now = Date()
        let calendar = Calendar.current
        
        switch selectedPeriod {
        case .week:
            let weekAgo = calendar.date(byAdding: .day, value: -7, to: now) ?? now
            return viewModel.services.filter { ($0.date ?? now) >= weekAgo }
        case .month:
            let monthAgo = calendar.date(byAdding: .month, value: -1, to: now) ?? now
            return viewModel.services.filter { ($0.date ?? now) >= monthAgo }
        case .year:
            let yearAgo = calendar.date(byAdding: .year, value: -1, to: now) ?? now
            return viewModel.services.filter { ($0.date ?? now) >= yearAgo }
        case .all:
            return viewModel.services
        }
    }
    
    var totalSpent: Double {
        filteredServices.reduce(0) { $0 + $1.price }
    }
    
    var averagePerService: Double {
        guard !filteredServices.isEmpty else { return 0 }
        return totalSpent / Double(filteredServices.count)
    }
    
    var categoryBreakdown: [(category: Category, total: Double, count: Int)] {
        var breakdown: [UUID: (category: Category, total: Double, count: Int)] = [:]
        
        for service in filteredServices {
            guard let category = service.category, let categoryId = category.id else { continue }
            
            if let existing = breakdown[categoryId] {
                breakdown[categoryId] = (
                    category: existing.category,
                    total: existing.total + service.price,
                    count: existing.count + 1
                )
            } else {
                breakdown[categoryId] = (category: category, total: service.price, count: 1)
            }
        }
        
        return breakdown.values.sorted { $0.total > $1.total }
    }
    
    var monthlyData: [(month: String, total: Double)] {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        
        var monthly: [String: Double] = [:]
        
        for service in filteredServices {
            guard let date = service.date else { continue }
            let monthKey = formatter.string(from: date)
            monthly[monthKey, default: 0] += service.price
        }
        
        return monthly.map { (month: $0.key, total: $0.value) }
            .sorted { formatter.date(from: $0.month) ?? Date() < formatter.date(from: $1.month) ?? Date() }
    }
    
    var body: some View {
        ThemeView(themeManager: themeManager) { theme in
            NavigationStack {
                ScrollView {
                    VStack(spacing: 24) {
                        
                        
                        // Summary Cards
//                        Picker("Period", selection: $selectedPeriod) {
//                            ForEach(Period.allCases, id: \.self) { period in
//                                Text(period.rawValue).tag(period)
//                            }
//                        }
//                        .pickerStyle(.segmented)
//                        .padding(.horizontal, 20)
                        
                        HStack(spacing: 16) {
                            StatSummaryCard(
                                title: "Total Spent",
                                value: PriceFormatter.formatCompact(totalSpent, currency: appSettings.currency),
                                icon: "dollarsign.circle.fill",
                                color: theme.accentColorValue,
                                theme: theme
                            )
                            
                            StatSummaryCard(
                                title: "Services",
                                value: "\(filteredServices.count)",
                                icon: "list.bullet",
                                color: Color(hex: "27AE60"),
                                theme: theme
                            )
                            
                            StatSummaryCard(
                                title: "Average",
                                value: PriceFormatter.formatCompact(averagePerService, currency: appSettings.currency),
                                icon: "chart.bar.fill",
                                color: Color(hex: "F39C12"),
                                theme: theme
                            )
                        }
                        .padding(.horizontal, 20)
                        
                        if filteredServices.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "chart.bar.doc.horizontal")
                                    .font(.system(size: 64))
                                    .foregroundColor(theme.textColorValue.opacity(0.3))
                                
                                Text("No data yet")
                                    .font(.system(size: 22, weight: .semibold))
                                    .foregroundColor(theme.textColorValue)
                                
                                Text("Add cards or import data\nto see statistics.")
                                    .font(.system(size: 15))
                                    .foregroundColor(theme.textColorValue.opacity(0.7))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 32)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                        } else {
                        
                        // Monthly Chart
                        if monthlyData.count > 1 {
                            let validMonthlyData = monthlyData.filter { $0.total > 0 }
                            if !validMonthlyData.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Spending Over Time")
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(theme.textColorValue)
                                        .padding(.horizontal, 20)
                                    
                                    Chart {
                                        ForEach(Array(validMonthlyData.enumerated()), id: \.offset) { index, data in
                                            BarMark(
                                                x: .value("Month", data.month),
                                                y: .value("Amount", data.total)
                                            )
                                            .foregroundStyle(theme.accentColorValue)
                                            .cornerRadius(8)
                                        }
                                    }
                                    .frame(height: 200)
                                    .padding()
                                    .background(theme.cardColorValue)
                                    .cornerRadius(20)
                                    .padding(.horizontal, 20)
                                }
                            }
                        }
                        
                        // Category Breakdown
                        VStack(alignment: .leading, spacing: 12) {
                            Text("By Category")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(theme.textColorValue)
                                .padding(.horizontal, 20)
                            
                            ForEach(Array(categoryBreakdown.prefix(5).enumerated()), id: \.offset) { index, item in
                                CategoryStatRow(
                                    category: item.category,
                                    total: item.total,
                                    count: item.count,
                                    percentage: totalSpent > 0 ? (item.total / totalSpent) * 100 : 0,
                                    rank: index + 1,
                                    theme: theme
                                )
                            }
                        }
                        .padding(.bottom, 20)
                        }
                    }
                    .padding(.vertical, 20)
                }
                .background(theme.backgroundColorValue)
                .navigationTitle("Statistics")
                .navigationBarTitleDisplayMode(.large)
                .toolbarColorScheme(theme.id == "dark" ? .dark : (theme.id == "light" ? .light : nil), for: .navigationBar)
            }
        }
        .onAppear {
            viewModel.loadData()
        }
    }
}

struct StatSummaryCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let theme: AppTheme
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(theme.textColorValue)
            
            Text(title)
                .font(.system(size: 12))
                .foregroundColor(theme.textColorValue.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(theme.cardColorValue)
        .cornerRadius(16)
    }
}

struct CategoryStatRow: View {
    let category: Category
    let total: Double
    let count: Int
    let percentage: Double
    let rank: Int
    let theme: AppTheme
    @Environment(AppSettings.self) private var appSettings
    
    var body: some View {
        HStack(spacing: 16) {
            // Rank
            ZStack {
                Circle()
                    .fill(Color(hex: category.colorName ?? "4A90E2").opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Text("\(rank)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color(hex: category.colorName ?? "4A90E2"))
            }
            
            // Category Icon
            Image(systemName: category.iconName ?? "folder.fill")
                .font(.system(size: 20))
                .foregroundColor(Color(hex: category.colorName ?? "4A90E2"))
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(category.name ?? "Unnamed")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(theme.textColorValue)
                
                Text("\(count) services • \(String(format: "%.1f", percentage))%")
                    .font(.system(size: 12))
                    .foregroundColor(theme.textColorValue.opacity(0.6))
            }
            
            Spacer()
            
            Text(PriceFormatter.formatCompact(total, currency: appSettings.currency))
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(theme.accentColorValue)
        }
        .padding()
        .background(theme.cardColorValue)
        .cornerRadius(16)
        .padding(.horizontal, 20)
    }
}
