import SwiftUI

struct TemplatesView: View {
    let viewModel: ServicesViewModel
    let themeManager: ThemeManager
    @Environment(AppSettings.self) private var appSettings
    @State private var templates: [ServiceTemplate] = []
    @State private var showTemplateForm: ServiceTemplate?
    
    var body: some View {
        ThemeView(themeManager: themeManager) { theme in
            NavigationStack {
                ScrollView {
                    VStack(spacing: 16) {
                        if templates.isEmpty {
                            VStack(spacing: 20) {
                                Image(systemName: "doc.text.fill")
                                    .font(.system(size: 60))
                                    .foregroundColor(theme.textColorValue.opacity(0.3))
                                
                                Text("No Templates")
                                    .font(.system(size: 24, weight: .semibold))
                                    .foregroundColor(theme.textColorValue)
                                
                                Text("Create templates for frequently used services")
                                    .font(.system(size: 16))
                                    .foregroundColor(theme.textColorValue.opacity(0.6))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 40)
                            }
                            .padding(.top, 60)
                        } else {
                            ForEach(templates) { template in
                                TemplateCard(
                                    template: template,
                                    viewModel: viewModel,
                                    theme: theme,
                                    onUse: {
                                        useTemplate(template)
                                    },
                                    onEdit: {
                                        showTemplateForm = template
                                    },
                                    onDelete: {
                                        deleteTemplate(template)
                                    }
                                )
                            }
                        }
                        
                        Button {
                            showTemplateForm = ServiceTemplate(
                                id: UUID(),
                                name: "",
                                categoryId: nil,
                                price: 0,
                                provider: "",
                                location: "",
                                note: ""
                            )
                        } label: {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Create Template")
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
                .navigationTitle("Templates")
                .navigationBarTitleDisplayMode(.large)
                .toolbarColorScheme(theme.id == "dark" ? .dark : (theme.id == "light" ? .light : nil), for: .navigationBar)
                .sheet(item: $showTemplateForm) { template in
                    TemplateFormView(
                        template: template,
                        viewModel: viewModel,
                        onSave: { savedTemplate in
                            if let index = templates.firstIndex(where: { $0.id == savedTemplate.id }) {
                                templates[index] = savedTemplate
                            } else {
                                templates.append(savedTemplate)
                            }
                            saveTemplates()
                        }
                    )
                    .onDisappear {
                        // Reload categories when form is dismissed
                        viewModel.loadData()
                    }
                }
                .onAppear {
                    viewModel.loadData()
                    loadTemplates()
                }
                .task(id: viewModel.categories.count) {
                    // Reload when categories change
                    viewModel.loadData()
                }
            }
        }
    }
    
    private func useTemplate(_ template: ServiceTemplate) {
        guard let category = viewModel.categories.first(where: { $0.id == template.categoryId }) else { return }
        
        do {
            try viewModel.addService(
                name: template.name,
                category: category,
                price: template.price,
                currency: appSettings.currency,
                date: Date(),
                provider: template.provider.isEmpty ? nil : template.provider,
                location: template.location.isEmpty ? nil : template.location,
                photoData: nil,
                note: template.note.isEmpty ? nil : template.note
            )
        } catch {
            print("Failed to add service from template: \(error.localizedDescription)")
        }
    }
    
    private func deleteTemplate(_ template: ServiceTemplate) {
        templates.removeAll { $0.id == template.id }
        saveTemplates()
    }
    
    private func loadTemplates() {
        if let data = UserDefaults.standard.data(forKey: "serviceTemplates"),
           let decoded = try? JSONDecoder().decode([ServiceTemplate].self, from: data) {
            templates = decoded
        }
    }
    
    private func saveTemplates() {
        if let encoded = try? JSONEncoder().encode(templates) {
            UserDefaults.standard.set(encoded, forKey: "serviceTemplates")
        }
    }
}

struct ServiceTemplate: Identifiable, Codable {
    let id: UUID
    var name: String
    var categoryId: UUID?
    var price: Double
    var provider: String
    var location: String
    var note: String
}

struct TemplateCard: View {
    let template: ServiceTemplate
    let viewModel: ServicesViewModel
    let theme: AppTheme
    let onUse: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    @Environment(AppSettings.self) private var appSettings
    
    var category: Category? {
        viewModel.categories.first { $0.id == template.categoryId }
    }
    
    var body: some View {
        HStack(spacing: 16) {
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
                Text(template.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(theme.textColorValue)
                
                if let category = category {
                    Text(category.name ?? "Category")
                        .font(.system(size: 14))
                        .foregroundColor(theme.textColorValue.opacity(0.6))
                }
                
                Text(PriceFormatter.format(template.price, currency: appSettings.currency))
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(theme.accentColorValue)
            }
            
            Spacer()
            
            Menu {
                Button {
                    onUse()
                } label: {
                    Label("Use Template", systemImage: "plus.circle")
                }
                
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
        .padding()
        .background(theme.cardColorValue)
        .cornerRadius(16)
        .padding(.horizontal, 20)
    }
}

struct TemplateFormView: View {
    let template: ServiceTemplate
    let viewModel: ServicesViewModel
    let onSave: (ServiceTemplate) -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String
    @State private var selectedCategoryId: UUID?
    @State private var price: String
    @State private var provider: String
    @State private var location: String
    @State private var note: String
    
    init(template: ServiceTemplate, viewModel: ServicesViewModel, onSave: @escaping (ServiceTemplate) -> Void) {
        self.template = template
        self.viewModel = viewModel
        self.onSave = onSave
        _name = State(initialValue: template.name)
        _selectedCategoryId = State(initialValue: template.categoryId)
        _price = State(initialValue: template.price > 0 ? String(format: "%.2f", template.price) : "")
        _provider = State(initialValue: template.provider)
        _location = State(initialValue: template.location)
        _note = State(initialValue: template.note)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Template Name") {
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
                
                Section("Price") {
                    TextField("Price", text: $price)
                        .keyboardType(.decimalPad)
                }
                
                Section("Additional Info") {
                    TextField("Provider (optional)", text: $provider)
                    TextField("Location (optional)", text: $location)
                    TextEditor(text: $note)
                        .frame(height: 100)
                }
            }
            .navigationTitle(template.name.isEmpty ? "New Template" : "Edit Template")
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
                        let updatedTemplate = ServiceTemplate(
                            id: template.id,
                            name: name,
                            categoryId: selectedCategoryId,
                            price: priceValue,
                            provider: provider,
                            location: location,
                            note: note
                        )
                        onSave(updatedTemplate)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}
