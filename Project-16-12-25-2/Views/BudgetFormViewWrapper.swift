import SwiftUI

struct BudgetFormViewWrapper: View {
    let viewModel: ServicesViewModel
    let onSave: (UUID?, Double) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var selectedCategory: Category?
    @State private var budgetText = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Category") {
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
            .navigationTitle("New Budget")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if let amount = Double(budgetText), 
                           let category = selectedCategory,
                           let categoryId = category.id {
                            onSave(categoryId, amount)
                        }
                        dismiss()
                    }
                    .disabled(selectedCategory == nil || budgetText.isEmpty)
                }
            }
            .onAppear {
                viewModel.loadData()
            }
        }
    }
}
