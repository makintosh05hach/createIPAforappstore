import Foundation
import CoreData
import SwiftUI

@Observable
class ServicesViewModel {
    private let context: NSManagedObjectContext
    var services: [Service] = []
    var categories: [Category] = []
    var searchText: String = ""
    var selectedCategory: Category?
    var selectedServices: Set<UUID> = []
    
    init(context: NSManagedObjectContext) {
        self.context = context
        loadData()
    }
    
    func loadData() {
        let serviceRequest: NSFetchRequest<Service> = Service.fetchRequest()
        let categoryRequest: NSFetchRequest<Category> = Category.fetchRequest()
        
        let categorySort = NSSortDescriptor(key: "sortOrder", ascending: true)
        categoryRequest.sortDescriptors = [categorySort]
        
        do {
            services = try context.fetch(serviceRequest)
            categories = try context.fetch(categoryRequest)
        } catch {
            print("Failed to load data: \(error.localizedDescription)")
            // Don't crash, just log the error
        }
    }
    
    func loadDataAsync() async {
        let serviceRequest: NSFetchRequest<Service> = Service.fetchRequest()
        let categoryRequest: NSFetchRequest<Category> = Category.fetchRequest()
        
        let categorySort = NSSortDescriptor(key: "sortOrder", ascending: true)
        categoryRequest.sortDescriptors = [categorySort]
        
        do {
            services = try context.fetch(serviceRequest)
            categories = try context.fetch(categoryRequest)
        } catch {
            print("Failed to load data: \(error.localizedDescription)")
        }
    }
    
    func filteredServices() -> [Service] {
        var filtered = services
        
        if !searchText.isEmpty {
            filtered = filtered.filter { service in
                (service.name?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (service.provider?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (service.note?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        
        if let category = selectedCategory {
            filtered = filtered.filter { $0.category == category }
        }
        
        return filtered
    }
    
    func servicesInCategory(_ category: Category) -> [Service] {
        services.filter { $0.category == category }
    }
    
    func averagePriceInCategory(_ category: Category) -> Double {
        let categoryServices = servicesInCategory(category)
        guard !categoryServices.isEmpty else { return 0 }
        let validPrices = categoryServices.map { $0.price }.filter { $0 >= 0 }
        guard !validPrices.isEmpty else { return 0 }
        let total = validPrices.reduce(0.0, +)
        return total / Double(validPrices.count)
    }
    
    func minPriceInCategory(_ category: Category) -> Double {
        let categoryServices = servicesInCategory(category)
        guard !categoryServices.isEmpty else { return 0 }
        let validPrices = categoryServices.map { $0.price }.filter { $0 >= 0 }
        return validPrices.min() ?? 0
    }
    
    func maxPriceInCategory(_ category: Category) -> Double {
        let categoryServices = servicesInCategory(category)
        guard !categoryServices.isEmpty else { return 0 }
        let validPrices = categoryServices.map { $0.price }.filter { $0 >= 0 }
        return validPrices.max() ?? 0
    }
    
    func addService(name: String, category: Category, price: Double, currency: String, date: Date, provider: String?, location: String?, photoData: Data?, note: String?) throws {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw ValidationError.emptyName
        }
        guard price >= 0 else {
            throw ValidationError.invalidPrice
        }
        guard price <= 1_000_000_000 else {
            throw ValidationError.priceTooLarge
        }
        
        let service = Service(context: context)
        service.id = UUID()
        service.name = name.trimmingCharacters(in: .whitespaces)
        service.category = category
        service.price = price
        service.currency = currency
        service.date = date
        service.provider = provider?.trimmingCharacters(in: .whitespaces).isEmpty == false ? provider?.trimmingCharacters(in: .whitespaces) : nil
        service.location = location?.trimmingCharacters(in: .whitespaces).isEmpty == false ? location?.trimmingCharacters(in: .whitespaces) : nil
        service.photoData = photoData
        service.note = note?.trimmingCharacters(in: .whitespaces).isEmpty == false ? note?.trimmingCharacters(in: .whitespaces) : nil
        service.isFavorite = false
        
        try PersistenceController.shared.save()
        loadData()
    }
    
    func updateService(_ service: Service, name: String, category: Category, price: Double, currency: String, date: Date, provider: String?, location: String?, photoData: Data?, note: String?) throws {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw ValidationError.emptyName
        }
        guard price >= 0 else {
            throw ValidationError.invalidPrice
        }
        guard price <= 1_000_000_000 else {
            throw ValidationError.priceTooLarge
        }
        
        service.name = name.trimmingCharacters(in: .whitespaces)
        service.category = category
        service.price = price
        service.currency = currency
        service.date = date
        service.provider = provider?.trimmingCharacters(in: .whitespaces).isEmpty == false ? provider?.trimmingCharacters(in: .whitespaces) : nil
        service.location = location?.trimmingCharacters(in: .whitespaces).isEmpty == false ? location?.trimmingCharacters(in: .whitespaces) : nil
        service.photoData = photoData
        service.note = note?.trimmingCharacters(in: .whitespaces).isEmpty == false ? note?.trimmingCharacters(in: .whitespaces) : nil
        
        try PersistenceController.shared.save()
        loadData()
    }
    
    func deleteService(_ service: Service) throws {
        context.delete(service)
        try PersistenceController.shared.save()
        loadData()
    }
    
    enum ValidationError: LocalizedError {
        case emptyName
        case invalidPrice
        case priceTooLarge
        
        var errorDescription: String? {
            switch self {
            case .emptyName:
                return "Service name cannot be empty"
            case .invalidPrice:
                return "Price must be a positive number"
            case .priceTooLarge:
                return "Price is too large"
            }
        }
    }
    
    func toggleFavorite(_ service: Service) throws {
        service.isFavorite.toggle()
        try PersistenceController.shared.save()
        loadData()
    }
    
    func duplicateService(_ service: Service) throws {
        let newService = Service(context: context)
        newService.id = UUID()
        newService.name = service.name
        newService.category = service.category
        newService.price = service.price
        newService.currency = service.currency
        newService.date = Date()
        newService.provider = service.provider
        newService.location = service.location
        newService.photoData = service.photoData
        newService.note = service.note
        newService.isFavorite = false
        
        try PersistenceController.shared.save()
        loadData()
    }
    
    func favorites() -> [Service] {
        services.filter { $0.isFavorite }
    }
    
    func addCategory(name: String, iconName: String, colorName: String) throws {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw ValidationError.emptyName
        }
        
        let category = Category(context: context)
        category.id = UUID()
        category.name = name.trimmingCharacters(in: .whitespaces)
        category.iconName = iconName
        category.colorName = colorName
        category.sortOrder = Int16(categories.count)
        
        try PersistenceController.shared.save()
        loadData()
    }
    
    func updateCategory(_ category: Category, name: String, iconName: String, colorName: String) throws {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw ValidationError.emptyName
        }
        
        category.name = name.trimmingCharacters(in: .whitespaces)
        category.iconName = iconName
        category.colorName = colorName
        
        try PersistenceController.shared.save()
        loadData()
    }
    
    func deleteCategory(_ category: Category) throws {
        context.delete(category)
        try PersistenceController.shared.save()
        loadData()
    }
    
    func reorderCategories(from source: IndexSet, to destination: Int) {
        categories.move(fromOffsets: source, toOffset: destination)
        for (index, category) in categories.enumerated() {
            category.sortOrder = Int16(index)
        }
        do {
            try PersistenceController.shared.save()
            loadData()
        } catch {
            print("Failed to save category reorder: \(error.localizedDescription)")
        }
    }
}
