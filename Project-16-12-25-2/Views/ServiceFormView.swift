import SwiftUI
import PhotosUI
import UIKit

struct ServiceFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppSettings.self) private var appSettings
    let viewModel: ServicesViewModel
    let themeManager: ThemeManager
    let service: Service?
    let preselectedCategory: Category?
    
    @State private var name = ""
    @State private var selectedCategory: Category?
    @State private var price = ""
    @State private var date = Date()
    @State private var provider = ""
    @State private var location = ""
    @State private var note = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var photoData: Data?
    @State private var showCategoryForm = false
    @State private var showTemplates = false
    @State private var selectedTemplate: ServiceTemplate?
    
    init(viewModel: ServicesViewModel, themeManager: ThemeManager, service: Service?, preselectedCategory: Category? = nil) {
        self.viewModel = viewModel
        self.themeManager = themeManager
        self.service = service
        self.preselectedCategory = preselectedCategory
    }
    
    init(viewModel: ServicesViewModel, themeManager: ThemeManager, service: Service?) {
        self.viewModel = viewModel
        self.themeManager = themeManager
        self.service = service
        self.preselectedCategory = nil
    }
    
    var body: some View {
        @Environment(\.colorScheme) var colorScheme
        let theme = themeManager.resolvedTheme(colorScheme: colorScheme)
        
        return NavigationStack {
            Form {
                Section("Service Details") {
                    TextField("Service name", text: $name)
                    
                    Picker("Category", selection: $selectedCategory) {
                        Text("Select category").tag(nil as Category?)
                        ForEach(viewModel.categories) { category in
                            HStack {
                                Image(systemName: category.iconName ?? "folder")
                                    .foregroundColor(Color(hex: category.colorName ?? "4A90E2"))
                                Text(category.name ?? "Unnamed")
                            }
                            .tag(category as Category?)
                        }
                    }
                    
                    Button("New category") {
                        showCategoryForm = true
                    }
                    .foregroundColor(themeManager.currentTheme.accentColorValue)
                }
                
                Section("Quick Add") {
                    Button {
                        showTemplates = true
                    } label: {
                        HStack {
                            Image(systemName: "doc.text.fill")
                            Text("Use Template")
                        }
                    }
                }
                
                Section("Price") {
                    HStack {
                        Text("Amount")
                        Spacer()
                        TextField("0.00", text: $price)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                Section("Additional Info") {
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    
                    TextField("Provider (optional)", text: $provider)
                    
                    TextField("Location (optional)", text: $location)
                    
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        HStack {
                            Text("Photo")
                            Spacer()
                            if photoData != nil {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            } else {
                                Image(systemName: "photo")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .onChange(of: selectedPhoto) { _, newItem in
                        Task {
                            if let data = try? await newItem?.loadTransferable(type: Data.self) {
                                photoData = data
                            }
                        }
                    }
                }
                
                Section("Notes") {
                    TextEditor(text: $note)
                        .frame(height: 100)
                }
            }
            .navigationTitle(service == nil ? "Add Service" : "Edit Service")
            .navigationBarTitleDisplayMode(.inline)
            .preferredColorScheme(theme.id == "dark" ? .dark : (theme.id == "light" ? .light : nil))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveService()
                    }
                    .disabled(name.isEmpty || selectedCategory == nil || price.isEmpty)
                }
            }
            .sheet(isPresented: $showCategoryForm) {
                CategoryFormView(
                    viewModel: viewModel,
                    themeManager: themeManager,
                    category: nil
                )
                .onDisappear {
                    // Reload categories when category form is dismissed
                    viewModel.loadData()
                }
            }
            .sheet(isPresented: $showTemplates) {
                TemplatesSelectionView(
                    viewModel: viewModel,
                    themeManager: themeManager,
                    onSelect: { template in
                        applyTemplate(template)
                    }
                )
            }
            .onAppear {
                viewModel.loadData()
                if let service = service {
                    loadService(service)
                } else if let preselected = preselectedCategory {
                    selectedCategory = preselected
                } else if let firstCategory = viewModel.categories.first {
                    selectedCategory = firstCategory
                }
            }
            .background(theme.backgroundColorValue)
        }
    }
    
    private func applyTemplate(_ template: ServiceTemplate) {
        name = template.name
        price = template.price > 0 ? String(format: "%.2f", template.price) : ""
        provider = template.provider
        location = template.location
        note = template.note
        
        if let categoryId = template.categoryId,
           let category = viewModel.categories.first(where: { $0.id == categoryId }) {
            selectedCategory = category
        }
    }
    
    private func loadService(_ service: Service) {
        name = service.name ?? ""
        selectedCategory = service.category
        price = String(format: "%.2f", service.price)
        date = service.date ?? Date()
        provider = service.provider ?? ""
        location = service.location ?? ""
        note = service.note ?? ""
        photoData = service.photoData
    }
    
    private func saveService() {
        guard let category = selectedCategory else {
            // Show error - category required
            return
        }
        
        guard let priceValue = Double(price), priceValue >= 0, priceValue <= 1_000_000_000 else {
            // Show error - invalid price
            return
        }
        
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            // Show error - name required
            return
        }
        
        // Optimize photo if needed
        let optimizedPhotoData = optimizePhotoIfNeeded(photoData)
        
        let currency = appSettings.currency
        
        do {
            if let service = service {
                try viewModel.updateService(
                    service,
                    name: name,
                    category: category,
                    price: priceValue,
                    currency: currency,
                    date: date,
                    provider: provider.isEmpty ? nil : provider,
                    location: location.isEmpty ? nil : location,
                    photoData: optimizedPhotoData,
                    note: note.isEmpty ? nil : note
                )
            } else {
                try viewModel.addService(
                    name: name,
                    category: category,
                    price: priceValue,
                    currency: currency,
                    date: date,
                    provider: provider.isEmpty ? nil : provider,
                    location: location.isEmpty ? nil : location,
                    photoData: optimizedPhotoData,
                    note: note.isEmpty ? nil : note
                )
            }
            dismiss()
        } catch {
            // Handle error - could show alert
            print("Failed to save service: \(error.localizedDescription)")
        }
    }
    
    private func optimizePhotoIfNeeded(_ photoData: Data?) -> Data? {
        guard let photoData = photoData else { return nil }
        
        // Limit photo size to 2MB
        guard photoData.count <= 2 * 1024 * 1024 else {
            // Compress image if too large
            guard let uiImage = UIImage(data: photoData) else { return photoData }
            guard let compressedData = uiImage.jpegData(compressionQuality: 0.5) else { return photoData }
            return compressedData.count <= 2 * 1024 * 1024 ? compressedData : photoData
        }
        
        return photoData
    }
}
