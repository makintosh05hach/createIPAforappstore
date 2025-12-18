import SwiftUI

struct BudgetView: View {
    let viewModel: ServicesViewModel
    let themeManager: ThemeManager
    @State private var categoryBudgets: [UUID: Double] = [:]
    @State private var showBudgetForm: Category?
    @State private var showAddBudget = false
    
    var body: some View {
        ThemeView(themeManager: themeManager) { theme in
            ScrollView {
                VStack(spacing: 20) {
                    if categoryBudgets.isEmpty {
                        VStack(spacing: 20) {
                            Image(systemName: "chart.pie.fill")
                                .font(.system(size: 60))
                                .foregroundColor(theme.textColorValue.opacity(0.3))
                            
                            Text("No Budgets Set")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(theme.textColorValue)
                            
                            Text("Set spending limits for categories to track your budget")
                                .font(.system(size: 16))
                                .foregroundColor(theme.textColorValue.opacity(0.6))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                        .padding(.top, 60)
                    } else {
                        ForEach(viewModel.categories.filter { categoryBudgets[$0.id ?? UUID()] != nil }) { category in
                            if let budget = categoryBudgets[category.id ?? UUID()] {
                                BudgetCard(
                                    category: category,
                                    budget: budget,
                                    spent: calculateSpent(for: category),
                                    viewModel: viewModel,
                                    theme: theme,
                                    onEdit: {
                                        showBudgetForm = category
                                    },
                                    onDelete: {
                                        categoryBudgets.removeValue(forKey: category.id ?? UUID())
                                        saveBudgets()
                                    }
                                )
                                .id("\(category.id?.uuidString ?? "")-\(viewModel.servicesInCategory(category).count)")
                            }
                        }
                    }
                    
                    // Add Budget Button
                    Button {
                        showAddBudget = true
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Budget")
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
            .navigationTitle("Budget")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(theme.id == "dark" ? .dark : (theme.id == "light" ? .light : nil), for: .navigationBar)
            .sheet(item: $showBudgetForm) { category in
                BudgetFormView(
                    category: category,
                    budget: categoryBudgets[category.id ?? UUID()] ?? 0,
                    onSave: { amount in
                        if amount > 0 {
                            categoryBudgets[category.id ?? UUID()] = amount
                        } else {
                            categoryBudgets.removeValue(forKey: category.id ?? UUID())
                        }
                        saveBudgets()
                    }
                )
            }
            .sheet(isPresented: $showAddBudget) {
                BudgetFormViewWrapper(
                    viewModel: viewModel,
                    onSave: { categoryId, amount in
                        guard let categoryId = categoryId, amount > 0 else { return }
                        categoryBudgets[categoryId] = amount
                        saveBudgets()
                    }
                )
                .onDisappear {
                    // Reload categories when form is dismissed
                    viewModel.loadData()
                }
            }
            .onAppear {
                viewModel.loadData()
                loadBudgets()
            }
            .refreshable {
                viewModel.loadData()
            }
            .task(id: viewModel.categories.count) {
                // Reload when categories change
                viewModel.loadData()
            }
        }
    }
    
    private func calculateSpent(for category: Category) -> Double {
        // Вычисляем сумму всех услуг в категории за текущий месяц
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? now
        
        let monthlySpent = viewModel.servicesInCategory(category)
            .filter { ($0.date ?? now) >= startOfMonth }
            .reduce(0) { $0 + $1.price }
        
        return monthlySpent
    }
    
    private func loadBudgets() {
        if let data = UserDefaults.standard.data(forKey: "categoryBudgets"),
           let decoded = try? JSONDecoder().decode([String: Double].self, from: data) {
            categoryBudgets = decoded.compactMapKeys { UUID(uuidString: $0) }
        }
    }
    
    private func saveBudgets() {
        let encoded = categoryBudgets.mapKeys { $0.uuidString }
        if let data = try? JSONEncoder().encode(encoded) {
            UserDefaults.standard.set(data, forKey: "categoryBudgets")
        }
    }
}

struct BudgetCard: View {
    let category: Category
    let budget: Double
    let spent: Double
    let viewModel: ServicesViewModel
    let theme: AppTheme
    let onEdit: () -> Void
    let onDelete: () -> Void
    @Environment(AppSettings.self) private var appSettings
    
    var percentage: Double {
        guard budget > 0 else { return 0 }
        return min((spent / budget) * 100, 100)
    }
    
    var isOverBudget: Bool {
        spent > budget
    }
    
    var remaining: Double {
        max(budget - spent, 0)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ZStack {
                    Circle()
                        .fill(Color(hex: category.colorName ?? "4A90E2").opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: category.iconName ?? "folder.fill")
                        .font(.system(size: 20))
                        .foregroundColor(Color(hex: category.colorName ?? "4A90E2"))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(category.name ?? "Unnamed")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(theme.textColorValue)
                    
                    Text("\(viewModel.servicesInCategory(category).count) services")
                        .font(.system(size: 14))
                        .foregroundColor(theme.textColorValue.opacity(0.6))
                }
                
                Spacer()
                
                Menu {
                    Button("Edit", action: onEdit)
                    Button(role: .destructive, action: onDelete) {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.gray)
                }
            }
            
            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 12)
                    
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isOverBudget ? Color.red : Color(hex: category.colorName ?? "4A90E2"))
                        .frame(width: geometry.size.width * min(percentage / 100, 1), height: 12)
                }
            }
            .frame(height: 12)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Spent (This Month)")
                        .font(.system(size: 12))
                        .foregroundColor(theme.textColorValue.opacity(0.6))
                    Text(PriceFormatter.format(spent, currency: appSettings.currency))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(isOverBudget ? .red : theme.textColorValue)
                }
                
                Spacer()
                
                VStack(alignment: .center, spacing: 4) {
                    Text("Monthly Budget")
                        .font(.system(size: 12))
                        .foregroundColor(theme.textColorValue.opacity(0.6))
                    Text(PriceFormatter.format(budget, currency: appSettings.currency))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(theme.textColorValue)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Remaining")
                        .font(.system(size: 12))
                        .foregroundColor(theme.textColorValue.opacity(0.6))
                    Text(PriceFormatter.format(remaining, currency: appSettings.currency))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(isOverBudget ? .red : .green)
                }
            }
            
            HStack {
                Text("\(String(format: "%.0f", percentage))% used")
                    .font(.system(size: 12))
                    .foregroundColor(theme.textColorValue.opacity(0.6))
                
                Spacer()
                
                let calendar = Calendar.current
                let now = Date()
                let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? now
                let monthlyCount = viewModel.servicesInCategory(category).filter { ($0.date ?? now) >= startOfMonth }.count
                
                Text("\(monthlyCount) services this month")
                    .font(.system(size: 11))
                    .foregroundColor(theme.textColorValue.opacity(0.5))
            }
        }
        .padding()
        .background(theme.cardColorValue)
        .cornerRadius(16)
        .padding(.horizontal, 20)
    }
}

struct BudgetFormView: View {
    let category: Category?
    let budget: Double
    let onSave: (Double) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var budgetText = ""
    @State private var selectedCategory: Category?
    @State private var viewModel: ServicesViewModel
    
    init(category: Category?, budget: Double, onSave: @escaping (Double) -> Void) {
        self.category = category
        self.budget = budget
        self.onSave = onSave
        let context = PersistenceController.shared.container.viewContext
        _viewModel = State(initialValue: ServicesViewModel(context: context))
        if let category = category {
            _selectedCategory = State(initialValue: category)
        } else {
            _selectedCategory = State(initialValue: nil)
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Category", selection: $selectedCategory) {
                        Text("Select Category").tag(nil as Category?)
                        ForEach(viewModel.categories) { category in
                            HStack {
                                Image(systemName: category.iconName ?? "folder.fill")
                                    .foregroundColor(Color(hex: category.colorName ?? "4A90E2"))
                                Text(category.name ?? "Unnamed")
                            }
                            .tag(category as Category?)
                        }
                    }
                } header: {
                    Text("Category")
                }
                
                Section {
                    TextField("Budget Amount", text: $budgetText)
                        .keyboardType(.decimalPad)
                } header: {
                    Text("Monthly Budget")
                } footer: {
                    Text("Set a spending limit for this category")
                }
            }
            .navigationTitle(category == nil ? "New Budget" : "Edit Budget")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if let amount = Double(budgetText), selectedCategory != nil {
                            onSave(amount)
                        }
                        dismiss()
                    }
                    .disabled(selectedCategory == nil || budgetText.isEmpty)
                }
            }
            .onAppear {
                viewModel.loadData()
                if budget > 0 {
                    budgetText = String(format: "%.2f", budget)
                }
            }
        }
    }
}

extension Dictionary {
    func compactMapKeys<T>(_ transform: (Key) throws -> T?) rethrows -> [T: Value] {
        try reduce(into: [T: Value]()) { result, element in
            if let key = try transform(element.key) {
                result[key] = element.value
            }
        }
    }
    
    func mapKeys<T>(_ transform: (Key) throws -> T) rethrows -> [T: Value] {
        try reduce(into: [T: Value]()) { result, element in
            let key = try transform(element.key)
            result[key] = element.value
        }
    }
}

