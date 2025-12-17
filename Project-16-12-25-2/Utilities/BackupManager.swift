import Foundation
import UIKit

class BackupManager {
    static func createBackup(services: [Service], categories: [Category]) -> URL? {
        var backup: [String: Any] = [:]
        
        // Services
        var servicesData: [[String: Any]] = []
        for service in services {
            var serviceDict: [String: Any] = [:]
            serviceDict["id"] = service.id?.uuidString
            serviceDict["name"] = service.name
            serviceDict["price"] = service.price
            serviceDict["currency"] = service.currency
            serviceDict["date"] = service.date?.timeIntervalSince1970
            serviceDict["provider"] = service.provider
            serviceDict["location"] = service.location
            serviceDict["note"] = service.note
            serviceDict["isFavorite"] = service.isFavorite
            serviceDict["categoryId"] = service.category?.id?.uuidString
            if let photoData = service.photoData {
                serviceDict["photoData"] = photoData.base64EncodedString()
            }
            servicesData.append(serviceDict)
        }
        backup["services"] = servicesData
        
        // Categories
        var categoriesData: [[String: Any]] = []
        for category in categories {
            var categoryDict: [String: Any] = [:]
            categoryDict["id"] = category.id?.uuidString
            categoryDict["name"] = category.name
            categoryDict["iconName"] = category.iconName
            categoryDict["colorName"] = category.colorName
            categoryDict["sortOrder"] = category.sortOrder
            categoriesData.append(categoryDict)
        }
        backup["categories"] = categoriesData
        
        backup["version"] = "1.0"
        backup["backupDate"] = Date().timeIntervalSince1970
        
        // Save to JSON
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HHmmss"
        let filename = "ServicePrices_Backup_\(formatter.string(from: Date())).json"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: backup, options: .prettyPrinted)
            try jsonData.write(to: tempURL)
            return tempURL
        } catch {
            print("Failed to create backup: \(error)")
            return nil
        }
    }
    
    static func restoreFromBackup(url: URL, context: NSManagedObjectContext) -> Bool {
        do {
            let data = try Data(contentsOf: url)
            guard let backup = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                return false
            }
            
            // Clear existing data
            let serviceRequest: NSFetchRequest<NSFetchRequestResult> = Service.fetchRequest()
            let categoryRequest: NSFetchRequest<NSFetchRequestResult> = Category.fetchRequest()
            
            let serviceDelete = NSBatchDeleteRequest(fetchRequest: serviceRequest)
            let categoryDelete = NSBatchDeleteRequest(fetchRequest: categoryRequest)
            
            try context.execute(serviceDelete)
            try context.execute(categoryDelete)
            
            // Restore categories first
            if let categoriesData = backup["categories"] as? [[String: Any]] {
                var categoryMap: [String: Category] = [:]
                
                for categoryDict in categoriesData {
                    let category = Category(context: context)
                    if let idString = categoryDict["id"] as? String,
                       let id = UUID(uuidString: idString) {
                        category.id = id
                        categoryMap[idString] = category
                    }
                    category.name = categoryDict["name"] as? String
                    category.iconName = categoryDict["iconName"] as? String
                    category.colorName = categoryDict["colorName"] as? String
                    category.sortOrder = (categoryDict["sortOrder"] as? Int16) ?? 0
                }
                
                // Restore services
                if let servicesData = backup["services"] as? [[String: Any]] {
                    for serviceDict in servicesData {
                        let service = Service(context: context)
                        if let idString = serviceDict["id"] as? String,
                           let id = UUID(uuidString: idString) {
                            service.id = id
                        }
                        service.name = serviceDict["name"] as? String
                        service.price = (serviceDict["price"] as? Double) ?? 0
                        service.currency = serviceDict["currency"] as? String
                        if let timestamp = serviceDict["date"] as? TimeInterval {
                            service.date = Date(timeIntervalSince1970: timestamp)
                        }
                        service.provider = serviceDict["provider"] as? String
                        service.location = serviceDict["location"] as? String
                        service.note = serviceDict["note"] as? String
                        service.isFavorite = (serviceDict["isFavorite"] as? Bool) ?? false
                        
                        if let categoryIdString = serviceDict["categoryId"] as? String {
                            service.category = categoryMap[categoryIdString]
                        }
                        
                        if let photoBase64 = serviceDict["photoData"] as? String,
                           let photoData = Data(base64Encoded: photoBase64) {
                            service.photoData = photoData
                        }
                    }
                }
            }
            
            try context.save()
            return true
        } catch {
            print("Failed to restore backup: \(error)")
            return false
        }
    }
}

import CoreData
