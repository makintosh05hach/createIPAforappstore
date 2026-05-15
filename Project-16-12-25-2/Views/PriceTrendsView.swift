import SwiftUI
import Charts

struct PriceTrendsView: View {
    let viewModel: ServicesViewModel
    let themeManager: ThemeManager
    @Environment(AppSettings.self) private var appSettings
    @State private var selectedCategory: Category?
    @State private var comparisonPeriod: ComparisonPeriod = .year
    
    enum ComparisonPeriod: String, CaseIterable {
        case month = "This Month vs Last Month"
        case year = "This Year vs Last Year"
        case all = "All Time Trend"
    }
    
    var categoryServices: [Service] {
        if let category = selectedCategory {
            return viewModel.servicesInCategory(category)
        }
        return viewModel.services
    }
    
    var comparisonData: [(period: String, average: Double, count: Int)] {
        let calendar = Calendar.current
        let now = Date()
        
        switch comparisonPeriod {
        case .month:
            let thisMonthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? now
            let lastMonthStart = calendar.date(byAdding: .month, value: -1, to: thisMonthStart) ?? now
            let lastMonthEnd = calendar.date(byAdding: .day, value: -1, to: thisMonthStart) ?? now
            
            let thisMonthServices = categoryServices.filter { ($0.date ?? now) >= thisMonthStart }
            let lastMonthServices = categoryServices.filter {
                guard let date = $0.date else { return false }
                return date >= lastMonthStart && date < thisMonthStart
            }
            
            let thisMonthAvg = thisMonthServices.isEmpty ? 0 : thisMonthServices.reduce(0) { $0 + $1.price } / Double(thisMonthServices.count)
            let lastMonthAvg = lastMonthServices.isEmpty ? 0 : lastMonthServices.reduce(0) { $0 + $1.price } / Double(lastMonthServices.count)
            
            return [
                (period: "Last Month", average: lastMonthAvg, count: lastMonthServices.count),
                (period: "This Month", average: thisMonthAvg, count: thisMonthServices.count)
            ]
            
        case .year:
            let thisYearStart = calendar.date(from: calendar.dateComponents([.year], from: now)) ?? now
            let lastYearStart = calendar.date(byAdding: .year, value: -1, to: thisYearStart) ?? now
            
            let thisYearServices = categoryServices.filter { ($0.date ?? now) >= thisYearStart }
            let lastYearServices = categoryServices.filter {
                guard let date = $0.date else { return false }
                return date >= lastYearStart && date < thisYearStart
            }
            
            let thisYearAvg = thisYearServices.isEmpty ? 0 : thisYearServices.reduce(0) { $0 + $1.price } / Double(thisYearServices.count)
            let lastYearAvg = lastYearServices.isEmpty ? 0 : lastYearServices.reduce(0) { $0 + $1.price } / Double(lastYearServices.count)
            
            return [
                (period: "Last Year", average: lastYearAvg, count: lastYearServices.count),
                (period: "This Year", average: thisYearAvg, count: thisYearServices.count)
            ]
            
        case .all:
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM yyyy"
            
            var monthly: [String: (total: Double, count: Int)] = [:]
            
            for service in categoryServices {
                guard let date = service.date else { continue }
                let monthKey = formatter.string(from: date)
                let current = monthly[monthKey] ?? (total: 0, count: 0)
                monthly[monthKey] = (total: current.total + service.price, count: current.count + 1)
            }
            
            return monthly.map { (period: $0.key, average: $0.value.count > 0 ? $0.value.total / Double($0.value.count) : 0, count: $0.value.count) }
                .sorted { formatter.date(from: $0.period) ?? Date() < formatter.date(from: $1.period) ?? Date() }
        }
    }
    
    var body: some View {
        ThemeView(themeManager: themeManager) { theme in
            ScrollView {
                VStack(spacing: 24) {
                    // Period Selector
                    Picker("Period", selection: $comparisonPeriod) {
                        ForEach(ComparisonPeriod.allCases, id: \.self) { period in
                            Text(period.rawValue).tag(period)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    
                    // Category Selector - moved to bottom as a button
                    Menu {
                        Button {
                            selectedCategory = nil
                        } label: {
                            HStack {
                                if selectedCategory == nil {
                                    Image(systemName: "checkmark")
                                }
                                Text("All Categories")
                            }
                        }
                        
                        ForEach(viewModel.categories) { category in
                            Button {
                                selectedCategory = category
                            } label: {
                                HStack {
                                    if selectedCategory?.id == category.id {
                                        Image(systemName: "checkmark")
                                    }
                                    Image(systemName: category.iconName ?? "folder.fill")
                                        .foregroundColor(Color(hex: category.colorName ?? "4A90E2"))
                                    Text(category.name ?? "Unnamed")
                                }
                            }
                        }
                    } label: {
                        HStack {
                            if let category = selectedCategory {
                                Image(systemName: category.iconName ?? "folder.fill")
                                    .foregroundColor(Color(hex: category.colorName ?? "4A90E2"))
                                Text(category.name ?? "Unnamed")
                            } else {
                                Image(systemName: "folder.fill")
                                Text("All Categories")
                            }
                            Spacer()
                            Image(systemName: "chevron.down")
                                .font(.system(size: 12))
                        }
                        .padding()
                        .background(theme.cardColorValue)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal, 20)
                        
                    // Main Chart - Always show
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Price Trend Analysis")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(theme.textColorValue)
                            .padding(.horizontal, 20)
                        
                        if comparisonData.count > 2 {
                            // Multi-period chart
                            Chart {
                                ForEach(Array(comparisonData.enumerated()), id: \.offset) { index, data in
                                    LineMark(
                                        x: .value("Period", data.period),
                                        y: .value("Average", data.average)
                                    )
                                    .foregroundStyle(theme.accentColorValue)
                                    .interpolationMethod(.catmullRom)
                                    .lineStyle(StrokeStyle(lineWidth: 3))
                                    
                                    AreaMark(
                                        x: .value("Period", data.period),
                                        y: .value("Average", data.average)
                                    )
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [
                                                theme.accentColorValue.opacity(0.3),
                                                theme.accentColorValue.opacity(0.0)
                                            ],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .interpolationMethod(.catmullRom)
                                    
                                    PointMark(
                                        x: .value("Period", data.period),
                                        y: .value("Average", data.average)
                                    )
                                    .foregroundStyle(theme.accentColorValue)
                                    .symbolSize(100)
                                }
                            }
                            .frame(height: 250)
                            .padding()
                            .background(theme.cardColorValue)
                            .cornerRadius(20)
                            .padding(.horizontal, 20)
                        } else if comparisonData.count == 2 {
                            // Comparison chart
                            let validData = comparisonData.filter { $0.average >= 0 }
                            if validData.count == 2 {
                                VStack(spacing: 20) {
                                    Chart {
                                        ForEach(Array(validData.enumerated()), id: \.offset) { index, data in
                                            BarMark(
                                                x: .value("Period", data.period),
                                                y: .value("Average", data.average)
                                            )
                                            .foregroundStyle(index == 1 ? theme.accentColorValue : theme.accentColorValue.opacity(0.6))
                                            .cornerRadius(8)
                                        }
                                    }
                                    .frame(height: 200)
                                    
                                    // Trend Indicator
                                    let change = validData[1].average - validData[0].average
                                    let changePercent = validData[0].average > 0 ? (change / validData[0].average) * 100 : 0
                                
                                HStack(spacing: 12) {
                                    Image(systemName: change > 0 ? "arrow.up.right.circle.fill" : change < 0 ? "arrow.down.right.circle.fill" : "minus.circle.fill")
                                        .font(.system(size: 32))
                                        .foregroundColor(change > 0 ? .red : change < 0 ? .green : .gray)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("\(change > 0 ? "+" : "")\(String(format: "%.1f", changePercent))%")
                                            .font(.system(size: 24, weight: .bold))
                                            .foregroundColor(change > 0 ? .red : change < 0 ? .green : .gray)
                                        
                                        Text("price change")
                                            .font(.system(size: 14))
                                            .foregroundColor(theme.textColorValue.opacity(0.6))
                                    }
                                    
                                    Spacer()
                                    
                                    VStack(alignment: .trailing, spacing: 4) {
                                        Text(PriceFormatter.formatCompact(abs(change), currency: appSettings.currency))
                                            .font(.system(size: 18, weight: .semibold))
                                            .foregroundColor(theme.textColorValue)
                                        
                                        Text("difference")
                                            .font(.system(size: 12))
                                            .foregroundColor(theme.textColorValue.opacity(0.6))
                                    }
                                }
                                .padding()
                                }
                                .padding()
                                .background(theme.cardColorValue)
                                .cornerRadius(20)
                                .padding(.horizontal, 20)
                                
                                // Comparison Cards
                                HStack(spacing: 16) {
                                    ForEach(Array(validData.prefix(2).enumerated()), id: \.offset) { index, data in
                                        PeriodComparisonCard(
                                            period: data.period,
                                            average: data.average,
                                            count: data.count,
                                            theme: theme,
                                            isCurrent: index == 1
                                        )
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                        } else {
                            VStack(spacing: 20) {
                                Image(systemName: "chart.line.uptrend.xyaxis")
                                    .font(.system(size: 60))
                                    .foregroundColor(theme.textColorValue.opacity(0.3))
                                
                                Text("Not Enough Data")
                                    .font(.system(size: 24, weight: .semibold))
                                    .foregroundColor(theme.textColorValue)
                                
                                Text("Add more services to see price trends")
                                    .font(.system(size: 16))
                                    .foregroundColor(theme.textColorValue.opacity(0.6))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 40)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 60)
                        }
                    }
                }
                .padding(.vertical, 20)
            }
            .background(theme.backgroundColorValue)
            .navigationTitle("Price Trends")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(theme.id == "dark" ? .dark : (theme.id == "light" ? .light : nil), for: .navigationBar)
            .onAppear {
                viewModel.loadData()
            }
            .task(id: viewModel.categories.count) {
                // Reload when categories change
                viewModel.loadData()
            }
        }
    }
}

struct PeriodComparisonCard: View {
    let period: String
    let average: Double
    let count: Int
    let theme: AppTheme
    let isCurrent: Bool
    @Environment(AppSettings.self) private var appSettings
    
    var body: some View {
        VStack(spacing: 8) {
            Text(period)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(theme.textColorValue.opacity(0.7))
            
            Text(PriceFormatter.formatCompact(average, currency: appSettings.currency))
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(isCurrent ? theme.accentColorValue : theme.textColorValue)
            
            Text("\(count) services")
                .font(.system(size: 12))
                .foregroundColor(theme.textColorValue.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(isCurrent ? theme.accentColorValue.opacity(0.1) : theme.cardColorValue)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isCurrent ? theme.accentColorValue : Color.clear, lineWidth: 2)
        )
    }
}
