import Foundation

struct PriceFormatter {
    static func format(_ price: Double, currency: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter.string(from: NSNumber(value: price)) ?? "\(currency) \(String(format: "%.2f", price))"
    }
    
    static func formatCompact(_ price: Double, currency: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: price)) ?? "\(currency) \(Int(price))"
    }
    
    static func formatWithDefault(_ price: Double, currency: String?, defaultCurrency: String = "USD") -> String {
        return format(price, currency: currency ?? defaultCurrency)
    }
    
    static func formatCompactWithDefault(_ price: Double, currency: String?, defaultCurrency: String = "USD") -> String {
        return formatCompact(price, currency: currency ?? defaultCurrency)
    }
}
