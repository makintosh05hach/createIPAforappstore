import SwiftUI

struct RecurringServicesView: View {
    let viewModel: ServicesViewModel
    let themeManager: ThemeManager
    @Environment(AppSettings.self) private var appSettings
    @State private var recurringServices: [RecurringService] = []
    @State private var showRecurringForm: RecurringService?
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    @State private var showSuccessAlert = false
    
    var body: some View {
        ThemeView(themeManager: themeManager) { theme in
            ScrollView {
                VStack(spacing: 16) {
                    if recurringServices.isEmpty {
                        VStack(spacing: 20) {
                            Image(systemName: "repeat.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(theme.textColorValue.opacity(0.3))
                            
                            Text("No Recurring Services")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(theme.textColorValue)
                            
                            Text("Track subscriptions and recurring services")
                                .font(.system(size: 16))
                                .foregroundColor(theme.textColorValue.opacity(0.6))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                        .padding(.top, 60)
                    } else {
                        ForEach(recurringServices) { recurring in
                            RecurringServiceCard(
                                recurring: recurring,
                                viewModel: viewModel,
                                theme: theme,
                                onEdit: {
                                    showRecurringForm = recurring
                                },
                                onDelete: {
                                    deleteRecurring(recurring)
                                },
                                onAddEntry: {
                                    addServiceFromRecurring(recurring)
                                }
                            )
                        }
                    }
                    
                    Button {
                        showRecurringForm = RecurringService(
                            id: UUID(),
                            name: "",
                            categoryId: nil,
                            price: 0,
                            frequency: .monthly,
                            provider: "",
                            lastAdded: nil
                        )
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Recurring Service")
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(theme.accentColorValue)
                        .cornerRadius(16)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
                .padding(.top, 20)
            }
            .background(theme.backgroundColorValue)
            .navigationTitle("Recurring Services")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(theme.id == "dark" ? .dark : (theme.id == "light" ? .light : nil), for: .navigationBar)
            .sheet(item: $showRecurringForm) { recurring in
                RecurringServiceFormView(
                    recurring: recurring,
                    viewModel: viewModel,
                    onSave: { savedRecurring in
                        if let index = recurringServices.firstIndex(where: { $0.id == savedRecurring.id }) {
                            recurringServices[index] = savedRecurring
                        } else {
                            recurringServices.append(savedRecurring)
                        }
                        saveRecurringServices()
                    }
                )
                .onDisappear {
                    // Reload categories when form is dismissed
                    viewModel.loadData()
                }
            }
            .onAppear {
                viewModel.loadData()
                loadRecurringServices()
            }
            .task(id: viewModel.categories.count) {
                // Reload when categories change
                viewModel.loadData()
            }
            .alert("Error", isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .alert("Success", isPresented: $showSuccessAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Service entry added successfully")
            }
        }
    }
    
    private func addServiceFromRecurring(_ recurring: RecurringService) {
        // Check if category exists
        guard let categoryId = recurring.categoryId else {
            errorMessage = "Please select a category for this recurring service"
            showErrorAlert = true
            return
        }
        
        guard let category = viewModel.categories.first(where: { $0.id == categoryId }) else {
            errorMessage = "Category not found. Please update this recurring service."
            showErrorAlert = true
            return
        }
        
        // Validate price
        guard recurring.price > 0 else {
            errorMessage = "Price must be greater than zero"
            showErrorAlert = true
            return
        }
        
        do {
            try viewModel.addService(
                name: recurring.name,
                category: category,
                price: recurring.price,
                currency: appSettings.currency,
                date: Date(),
                provider: recurring.provider.isEmpty ? nil : recurring.provider,
                location: nil,
                photoData: nil,
                note: "Recurring service"
            )
            
            // Reload viewModel to show new service
            viewModel.loadData()
            
            // Update last added date
            if let index = recurringServices.firstIndex(where: { $0.id == recurring.id }) {
                recurringServices[index].lastAdded = Date()
                saveRecurringServices()
            }
            
            // Show success message
            showSuccessAlert = true
        } catch {
            errorMessage = "Failed to add service: \(error.localizedDescription)"
            showErrorAlert = true
        }
    }
    
    private func deleteRecurring(_ recurring: RecurringService) {
        recurringServices.removeAll { $0.id == recurring.id }
        saveRecurringServices()
    }
    
    private func loadRecurringServices() {
        if let data = UserDefaults.standard.data(forKey: "recurringServices"),
           let decoded = try? JSONDecoder().decode([RecurringService].self, from: data) {
            recurringServices = decoded
        }
    }
    
    private func saveRecurringServices() {
        if let encoded = try? JSONEncoder().encode(recurringServices) {
            UserDefaults.standard.set(encoded, forKey: "recurringServices")
        }
    }
}

struct RecurringService: Identifiable, Codable {
    let id: UUID
    var name: String
    var categoryId: UUID?
    var price: Double
    var frequency: Frequency
    var provider: String
    var lastAdded: Date?
    
    enum Frequency: String, Codable, CaseIterable {
        case weekly = "Weekly"
        case monthly = "Monthly"
        case quarterly = "Quarterly"
        case yearly = "Yearly"
    }
}

struct RecurringServiceCard: View {
    let recurring: RecurringService
    let viewModel: ServicesViewModel
    let theme: AppTheme
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onAddEntry: () -> Void
    @Environment(AppSettings.self) private var appSettings
    
    var category: Category? {
        viewModel.categories.first { $0.id == recurring.categoryId }
    }
    
    var nextDue: String {
        guard let lastAdded = recurring.lastAdded else { return "Not started" }
        let calendar = Calendar.current
        var components = DateComponents()
        
        switch recurring.frequency {
        case .weekly:
            components.day = 7
        case .monthly:
            components.month = 1
        case .quarterly:
            components.month = 3
        case .yearly:
            components.year = 1
        }
        
        if let nextDate = calendar.date(byAdding: components, to: lastAdded) {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return formatter.string(from: nextDate)
        }
        return "Unknown"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                if let category = category {
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
                    Text(recurring.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(theme.textColorValue)
                    
                    Text(recurring.frequency.rawValue)
                        .font(.system(size: 14))
                        .foregroundColor(theme.textColorValue.opacity(0.6))
                }
                
                Spacer()
                
                HStack(spacing: 12) {
                    Button {
                        onAddEntry()
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Entry")
                        }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(theme.accentColorValue)
                        .cornerRadius(8)
                    }
                    
                    Menu {
                        Button {
                            onEdit()
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        
                        Button(role: .destructive) {
                            onDelete()
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .foregroundColor(.gray)
                    }
                }
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Price")
                        .font(.system(size: 12))
                        .foregroundColor(theme.textColorValue.opacity(0.6))
                    Text(PriceFormatter.format(recurring.price, currency: appSettings.currency))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(theme.accentColorValue)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Next Due")
                        .font(.system(size: 12))
                        .foregroundColor(theme.textColorValue.opacity(0.6))
                    Text(nextDue)
                        .font(.system(size: 14))
                        .foregroundColor(theme.textColorValue)
                }
            }
        }
        .padding()
        .background(theme.cardColorValue)
        .cornerRadius(16)
        .padding(.horizontal, 20)
    }
}

struct RecurringServiceFormView: View {
    let recurring: RecurringService
    let viewModel: ServicesViewModel
    let onSave: (RecurringService) -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String
    @State private var selectedCategoryId: UUID?
    @State private var price: String
    @State private var frequency: RecurringService.Frequency
    @State private var provider: String
    
    init(recurring: RecurringService, viewModel: ServicesViewModel, onSave: @escaping (RecurringService) -> Void) {
        self.recurring = recurring
        self.viewModel = viewModel
        self.onSave = onSave
        _name = State(initialValue: recurring.name)
        _selectedCategoryId = State(initialValue: recurring.categoryId)
        _price = State(initialValue: recurring.price > 0 ? String(format: "%.2f", recurring.price) : "")
        _frequency = State(initialValue: recurring.frequency)
        _provider = State(initialValue: recurring.provider)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Service Name") {
                    TextField("Service name", text: $name)
                }
                
                Section("Category") {
                    Picker("Category", selection: $selectedCategoryId) {
                        Text("None").tag(nil as UUID?)
                        ForEach(viewModel.categories) { category in
                            Text(category.name ?? "Unnamed").tag(category.id as UUID?)
                        }
                    }
                }
                
                Section("Price & Frequency") {
                    TextField("Price", text: $price)
                        .keyboardType(.decimalPad)
                    
                    Picker("Frequency", selection: $frequency) {
                        ForEach(RecurringService.Frequency.allCases, id: \.self) { freq in
                            Text(freq.rawValue).tag(freq)
                        }
                    }
                }
                
                Section("Provider") {
                    TextField("Provider (optional)", text: $provider)
                }
            }
            .navigationTitle(recurring.name.isEmpty ? "New Recurring Service" : "Edit Recurring Service")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let priceValue = Double(price) ?? 0
                        let updatedRecurring = RecurringService(
                            id: recurring.id,
                            name: name,
                            categoryId: selectedCategoryId,
                            price: priceValue,
                            frequency: frequency,
                            provider: provider,
                            lastAdded: recurring.lastAdded
                        )
                        onSave(updatedRecurring)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}
