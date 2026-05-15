import SwiftUI

struct ComparisonView: View {
    let viewModel: ServicesViewModel
    let themeManager: ThemeManager
    @State private var selectedServices: Set<UUID> = []
    @State private var showComparison = false
    
    var selectedServicesList: [Service] {
        viewModel.services.filter { selectedServices.contains($0.id ?? UUID()) }
    }
    
    var body: some View {
        ThemeView(themeManager: themeManager) { theme in
            ZStack {
                theme.backgroundColorValue
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    if viewModel.services.isEmpty {
                        VStack(spacing: 20) {
                            Image(systemName: "square.grid.2x2")
                                .font(.system(size: 60))
                                .foregroundColor(theme.textColorValue.opacity(0.3))
                            
                            Text("No Services Yet")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(theme.textColorValue)
                            
                            Text("Add services to compare their prices")
                                .font(.system(size: 16))
                                .foregroundColor(theme.textColorValue.opacity(0.6))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        VStack(spacing: 12) {
                            if selectedServices.isEmpty {
                                VStack(spacing: 8) {
                                    Text("Tap services to select them")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(theme.textColorValue.opacity(0.7))
                                    
                                    Text("Select at least 2 services to compare")
                                        .font(.system(size: 14))
                                        .foregroundColor(theme.textColorValue.opacity(0.5))
                                }
                                .padding(.vertical, 8)
                            } else {
                                HStack {
                                    Text("\(selectedServices.count) selected")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(theme.textColorValue)
                                    
                                    Spacer()
                                    
                                    if selectedServices.count >= 2 {
                                        Button("Compare") {
                                            showComparison = true
                                        }
                                        .buttonStyle(.borderedProminent)
                                        .controlSize(.regular)
                                    } else {
                                        Text("Select at least 2")
                                            .font(.system(size: 14))
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 8)
                            }
                        }
                    }
                    
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.services) { service in
                                ComparisonServiceRow(
                                    service: service,
                                    isSelected: selectedServices.contains(service.id ?? UUID()),
                                    theme: theme
                                ) {
                                    toggleSelection(for: service)
                                }
                            }
                        }
                        .padding(20)
                    }
                }
            }
            .navigationTitle("Compare Prices")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(theme.id == "dark" ? .dark : (theme.id == "light" ? .light : nil), for: .navigationBar)
            .toolbar {
                if !selectedServices.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Clear") {
                            selectedServices.removeAll()
                        }
                    }
                }
            }
            .sheet(isPresented: $showComparison) {
                ComparisonDetailView(
                    services: selectedServicesList,
                    themeManager: themeManager
                )
            }
        }
    }
    
    private func toggleSelection(for service: Service) {
        guard let id = service.id else { return }
        if selectedServices.contains(id) {
            selectedServices.remove(id)
        } else {
            selectedServices.insert(id)
        }
    }
}

struct ComparisonServiceRow: View {
    let service: Service
    let isSelected: Bool
    let theme: AppTheme
    let onTap: () -> Void
    @Environment(AppSettings.self) private var appSettings
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? theme.accentColorValue : .gray)
                    .font(.system(size: 24))
                
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
                }
                
                Spacer()
                
                Text(PriceFormatter.format(service.price, currency: service.currency ?? appSettings.currency))
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(theme.accentColorValue)
            }
            .padding()
            .background(isSelected ? theme.accentColorValue.opacity(0.1) : theme.cardColorValue)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? theme.accentColorValue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

struct ComparisonDetailView: View {
    let services: [Service]
    let themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    
    var cheapestService: Service? {
        services.min(by: { $0.price < $1.price })
    }
    
    var body: some View {
        ThemeView(themeManager: themeManager) { theme in
            NavigationStack {
                ScrollView {
                    VStack(spacing: 20) {
                        if let cheapest = cheapestService {
                            HStack {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.yellow)
                                Text("Best Value: \(cheapest.name ?? "Unnamed")")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(theme.textColorValue)
                            }
                            .padding()
                            .background(theme.cardColorValue)
                            .cornerRadius(16)
                            .padding(.horizontal, 20)
                        }
                        
                        ForEach(services) { service in
                            ComparisonCard(service: service, isCheapest: service.id == cheapestService?.id, theme: theme)
                                .padding(.horizontal, 20)
                        }
                    }
                    .padding(.vertical, 20)
                }
                .background(theme.backgroundColorValue)
                .navigationTitle("Price Comparison")
                .navigationBarTitleDisplayMode(.inline)
                .toolbarColorScheme(theme.id == "dark" ? .dark : (theme.id == "light" ? .light : nil), for: .navigationBar)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
            }
        }
    }
}

struct ComparisonCard: View {
    let service: Service
    let isCheapest: Bool
    let theme: AppTheme
    @Environment(AppSettings.self) private var appSettings
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(service.name ?? "Unnamed")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(theme.textColorValue)
                
                Spacer()
                
                if isCheapest {
                    Text("BEST")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green)
                        .cornerRadius(8)
                }
            }
            
            if let category = service.category {
                Text(category.name ?? "Category")
                    .font(.system(size: 14))
                    .foregroundColor(theme.textColorValue.opacity(0.6))
            }
            
            Divider()
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Price")
                        .font(.system(size: 14))
                        .foregroundColor(theme.textColorValue.opacity(0.6))
                    Text(PriceFormatter.format(service.price, currency: service.currency ?? appSettings.currency))
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(theme.accentColorValue)
                }
                
                Spacer()
                
                if let date = service.date {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Date")
                            .font(.system(size: 14))
                            .foregroundColor(theme.textColorValue.opacity(0.6))
                        Text(date, style: .date)
                            .font(.system(size: 16))
                            .foregroundColor(theme.textColorValue)
                    }
                }
            }
            
            if let provider = service.provider {
                HStack {
                    Image(systemName: "person.fill")
                    Text(provider)
                }
                .font(.system(size: 14))
                .foregroundColor(theme.textColorValue.opacity(0.7))
            }
        }
        .padding()
        .background(isCheapest ? theme.accentColorValue.opacity(0.1) : theme.cardColorValue)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(isCheapest ? theme.accentColorValue : Color.clear, lineWidth: 2)
        )
    }
}
