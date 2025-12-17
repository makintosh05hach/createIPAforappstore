import Foundation

class CSVExporter {
    static func generateCSV(services: [Service], categories: [Category]) -> URL? {
        var csvContent = "Name,Category,Price,Currency,Date,Provider,Location,Note\n"
        
        for service in services.sorted(by: { ($0.date ?? Date()) > ($1.date ?? Date()) }) {
            let name = (service.name ?? "").replacingOccurrences(of: ",", with: ";")
            let category = (service.category?.name ?? "").replacingOccurrences(of: ",", with: ";")
            let price = String(format: "%.2f", service.price)
            let currency = service.currency ?? "USD"
            let date = service.date.map { formatDate($0) } ?? ""
            let provider = (service.provider ?? "").replacingOccurrences(of: ",", with: ";")
            let location = (service.location ?? "").replacingOccurrences(of: ",", with: ";")
            let note = (service.note ?? "").replacingOccurrences(of: ",", with: ";").replacingOccurrences(of: "\n", with: " ")
            
            csvContent += "\(name),\(category),\(price),\(currency),\(date),\(provider),\(location),\(note)\n"
        }
        
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("ServicePrices_\(formatDateForFilename(Date())).csv")
        
        do {
            try csvContent.write(to: tempURL, atomically: true, encoding: .utf8)
            return tempURL
        } catch {
            print("Failed to save CSV: \(error)")
            return nil
        }
    }
    
    private static func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    
    private static func formatDateForFilename(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HHmmss"
        return formatter.string(from: date)
    }
}
