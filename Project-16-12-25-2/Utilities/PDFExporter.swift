import Foundation
import PDFKit
import UIKit
import SwiftUI

class PDFExporter {
    static func generatePDF(services: [Service], categories: [Category], currency: String = "USD") -> URL? {
        let pdfMetaData = [
            kCGPDFContextCreator: "Personal Service Price List",
            kCGPDFContextAuthor: "User",
            kCGPDFContextTitle: "My Service Prices \(Calendar.current.component(.year, from: Date()))"
        ]
        
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let pageWidth = 8.5 * 72.0
        let pageHeight = 11 * 72.0
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        let data = renderer.pdfData { context in
            context.beginPage()
            
            var yPosition: CGFloat = 60
            
            // Title
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 32),
                .foregroundColor: UIColor.black
            ]
            let title = "My Service Prices \(Calendar.current.component(.year, from: Date()))"
            title.draw(at: CGPoint(x: 60, y: yPosition), withAttributes: titleAttributes)
            yPosition += 50
            
            // Summary
            let summaryAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 16),
                .foregroundColor: UIColor.gray
            ]
            let summary = "\(services.count) services in \(categories.count) categories"
            summary.draw(at: CGPoint(x: 60, y: yPosition), withAttributes: summaryAttributes)
            yPosition += 40
            
            // Categories
            for category in categories {
                let categoryServices = services.filter { $0.category == category }
                guard !categoryServices.isEmpty else { continue }
                
                // Check if we need a new page
                if yPosition > pageHeight - 200 {
                    context.beginPage()
                    yPosition = 60
                }
                
                // Category header
                let categoryAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.boldSystemFont(ofSize: 24),
                    .foregroundColor: UIColor(hex: category.colorName ?? "4A90E2")
                ]
                let categoryName = category.name ?? "Unnamed Category"
                categoryName.draw(at: CGPoint(x: 60, y: yPosition), withAttributes: categoryAttributes)
                yPosition += 30
                
                // Average price
                let average = categoryServices.reduce(0.0) { $0 + $1.price } / Double(categoryServices.count)
                let averageText = "Average: \(formatPrice(average, currency: currency))"
                let averageAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 14),
                    .foregroundColor: UIColor.gray
                ]
                averageText.draw(at: CGPoint(x: 60, y: yPosition), withAttributes: averageAttributes)
                yPosition += 25
                
                // Services
                for service in categoryServices.sorted(by: { ($0.date ?? Date()) > ($1.date ?? Date()) }) {
                    if yPosition > pageHeight - 100 {
                        context.beginPage()
                        yPosition = 60
                    }
                    
                    let serviceText = "• \(service.name ?? "Unnamed") - \(formatPrice(service.price, currency: service.currency ?? currency))"
                    let serviceAttributes: [NSAttributedString.Key: Any] = [
                        .font: UIFont.systemFont(ofSize: 12),
                        .foregroundColor: UIColor.black
                    ]
                    serviceText.draw(at: CGPoint(x: 80, y: yPosition), withAttributes: serviceAttributes)
                    yPosition += 20
                    
                    if let date = service.date {
                        let dateText = "  \(formatDate(date))"
                        let dateAttributes: [NSAttributedString.Key: Any] = [
                            .font: UIFont.systemFont(ofSize: 10),
                            .foregroundColor: UIColor.lightGray
                        ]
                        dateText.draw(at: CGPoint(x: 80, y: yPosition), withAttributes: dateAttributes)
                        yPosition += 18
                    }
                }
                
                yPosition += 20
            }
        }
        
        // Save to temporary file
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("ServicePrices.pdf")
        do {
            try data.write(to: tempURL)
            return tempURL
        } catch {
            print("Failed to save PDF: \(error)")
            return nil
        }
    }
    
    static func generateServiceImage(service: Service, themeManager: ThemeManager) -> UIImage? {
        let size = CGSize(width: 400, height: 600)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            let backgroundColor = themeManager.currentTheme.backgroundColorValue
            UIColor(backgroundColor).setFill()
            context.fill(CGRect(origin: .zero, size: size))
            
            var yPosition: CGFloat = 40
            
            // Title
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 28),
                .foregroundColor: UIColor(themeManager.currentTheme.textColorValue)
            ]
            let title = service.name ?? "Service"
            title.draw(at: CGPoint(x: 40, y: yPosition), withAttributes: titleAttributes)
            yPosition += 50
            
            // Price
            let priceAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 36),
                .foregroundColor: UIColor(themeManager.currentTheme.accentColorValue)
            ]
            let price = formatPrice(service.price, currency: service.currency ?? "USD")
            price.draw(at: CGPoint(x: 40, y: yPosition), withAttributes: priceAttributes)
            yPosition += 60
            
            // Details
            if let date = service.date {
                let dateText = "Date: \(formatDate(date))"
                let dateAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 16),
                    .foregroundColor: UIColor.gray
                ]
                dateText.draw(at: CGPoint(x: 40, y: yPosition), withAttributes: dateAttributes)
                yPosition += 30
            }
            
            if let provider = service.provider {
                let providerText = "Provider: \(provider)"
                let providerAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 16),
                    .foregroundColor: UIColor.gray
                ]
                providerText.draw(at: CGPoint(x: 40, y: yPosition), withAttributes: providerAttributes)
                yPosition += 30
            }
            
            if let note = service.note {
                let noteAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 14),
                    .foregroundColor: UIColor.darkGray
                ]
                let noteRect = CGRect(x: 40, y: yPosition, width: 320, height: 200)
                note.draw(in: noteRect, withAttributes: noteAttributes)
            }
        }
    }
    
    private static func formatPrice(_ price: Double, currency: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        return formatter.string(from: NSNumber(value: price)) ?? "$\(String(format: "%.2f", price))"
    }
    
    private static func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

extension UIColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            red: CGFloat(r) / 255,
            green: CGFloat(g) / 255,
            blue: CGFloat(b) / 255,
            alpha: CGFloat(a) / 255
        )
    }
    
    convenience init(_ color: Color) {
        let uiColor = UIColor(color)
        self.init(cgColor: uiColor.cgColor)
    }
}
