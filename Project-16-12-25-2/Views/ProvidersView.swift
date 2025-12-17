import SwiftUI

struct ProvidersView: View {
    let viewModel: ServicesViewModel
    let themeManager: ThemeManager
    @State private var providerRatings: [String: (rating: Double, count: Int)] = [:]
    
    var providers: [(name: String, rating: Double, count: Int, totalSpent: Double)] {
        var providerData: [String: (rating: Double, count: Int, totalSpent: Double)] = [:]
        
        for service in viewModel.services {
            guard let provider = service.provider, !provider.isEmpty else { continue }
            
            let currentRating = providerRatings[provider]?.rating ?? 5.0
            let currentCount = providerData[provider]?.count ?? 0
            let currentTotal = providerData[provider]?.totalSpent ?? 0
            
            providerData[provider] = (
                rating: currentRating,
                count: currentCount + 1,
                totalSpent: currentTotal + service.price
            )
        }
        
        return providerData.map { (name: $0.key, rating: $0.value.rating, count: $0.value.count, totalSpent: $0.value.totalSpent) }
            .sorted { $0.rating > $1.rating }
    }
    
    var body: some View {
        ThemeView(themeManager: themeManager) { theme in
            NavigationStack {
                ScrollView {
                    VStack(spacing: 16) {
                        if providers.isEmpty {
                            VStack(spacing: 20) {
                                Image(systemName: "person.3.fill")
                                    .font(.system(size: 60))
                                    .foregroundColor(theme.textColorValue.opacity(0.3))
                                
                                Text("No Providers")
                                    .font(.system(size: 24, weight: .semibold))
                                    .foregroundColor(theme.textColorValue)
                                
                                Text("Add providers to your services to see ratings")
                                    .font(.system(size: 16))
                                    .foregroundColor(theme.textColorValue.opacity(0.6))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 40)
                            }
                            .padding(.top, 60)
                        } else {
                            ForEach(providers, id: \.name) { provider in
                                ProviderCard(
                                    name: provider.name,
                                    rating: provider.rating,
                                    count: provider.count,
                                    totalSpent: provider.totalSpent,
                                    theme: theme,
                                    onRate: { newRating in
                                        providerRatings[provider.name] = (rating: newRating, count: provider.count)
                                        saveRatings()
                                    }
                                )
                            }
                        }
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 20)
                }
                .background(theme.backgroundColorValue)
                .navigationTitle("Providers")
                .navigationBarTitleDisplayMode(.large)
                .toolbarColorScheme(theme.id == "dark" ? .dark : (theme.id == "light" ? .light : nil), for: .navigationBar)
                .onAppear {
                    loadRatings()
                }
            }
        }
    }
    
    private func loadRatings() {
        if let data = UserDefaults.standard.data(forKey: "providerRatings"),
           let decoded = try? JSONDecoder().decode([String: Double].self, from: data) {
            providerRatings = decoded.mapValues { (rating: $0, count: 0) }
        }
    }
    
    private func saveRatings() {
        let ratings = providerRatings.mapValues { $0.rating }
        if let encoded = try? JSONEncoder().encode(ratings) {
            UserDefaults.standard.set(encoded, forKey: "providerRatings")
        }
    }
}

struct ProviderCard: View {
    let name: String
    let rating: Double
    let count: Int
    let totalSpent: Double
    let theme: AppTheme
    let onRate: (Double) -> Void
    @Environment(AppSettings.self) private var appSettings
    
    @State private var showRatingPicker = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(name)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(theme.textColorValue)
                    
                    Text("\(count) service\(count == 1 ? "" : "s")")
                        .font(.system(size: 14))
                        .foregroundColor(theme.textColorValue.opacity(0.6))
                }
                
                Spacer()
                
                Button {
                    showRatingPicker = true
                } label: {
                    HStack(spacing: 4) {
                        ForEach(1...5, id: \.self) { star in
                            Image(systemName: star <= Int(rating) ? "star.fill" : "star")
                                .foregroundColor(star <= Int(rating) ? .yellow : .gray)
                                .font(.system(size: 16))
                        }
                    }
                }
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total Spent")
                        .font(.system(size: 12))
                        .foregroundColor(theme.textColorValue.opacity(0.6))
                    Text(PriceFormatter.format(totalSpent, currency: appSettings.currency))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(theme.accentColorValue)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Average")
                        .font(.system(size: 12))
                        .foregroundColor(theme.textColorValue.opacity(0.6))
                    Text(PriceFormatter.format(totalSpent / Double(count), currency: appSettings.currency))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(theme.textColorValue)
                }
            }
        }
        .padding()
        .background(theme.cardColorValue)
        .cornerRadius(16)
        .padding(.horizontal, 20)
        .sheet(isPresented: $showRatingPicker) {
            RatingPickerView(
                currentRating: rating,
                onSelect: onRate
            )
        }
    }
}

struct RatingPickerView: View {
    let currentRating: Double
    let onSelect: (Double) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var selectedRating: Double
    
    init(currentRating: Double, onSelect: @escaping (Double) -> Void) {
        self.currentRating = currentRating
        self.onSelect = onSelect
        _selectedRating = State(initialValue: currentRating)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                Text("Rate Provider")
                    .font(.system(size: 24, weight: .bold))
                    .padding(.top, 40)
                
                HStack(spacing: 8) {
                    ForEach(1...5, id: \.self) { star in
                        Button {
                            selectedRating = Double(star)
                        } label: {
                            Image(systemName: star <= Int(selectedRating) ? "star.fill" : "star")
                                .foregroundColor(star <= Int(selectedRating) ? .yellow : .gray)
                                .font(.system(size: 40))
                        }
                    }
                }
                
                Text("\(Int(selectedRating)) out of 5")
                    .font(.system(size: 18, weight: .medium))
                
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSelect(selectedRating)
                        dismiss()
                    }
                }
            }
        }
    }
}
