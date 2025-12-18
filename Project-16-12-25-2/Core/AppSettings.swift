import Foundation

@Observable
class AppSettings {
    var currency: String {
        didSet {
            UserDefaults.standard.set(currency, forKey: "selectedCurrency")
        }
    }
    
    var defaultSortOrder: SortOrder {
        didSet {
            UserDefaults.standard.set(defaultSortOrder.rawValue, forKey: "defaultSortOrder")
        }
    }
    
    var hasCompletedOnboarding: Bool {
        didSet {
            UserDefaults.standard.set(hasCompletedOnboarding, forKey: "hasCompletedOnboarding")
        }
    }
    
    enum SortOrder: String, CaseIterable, Hashable {
        case price = "Price"
        case date = "Date"
        case name = "Name"
    }
    
    static let availableCurrencies = [
        "USD", "EUR", "GBP", "JPY", "CNY", "AUD", "CAD", "CHF", "INR", "RUB",
        "BRL", "MXN", "KRW", "SGD", "HKD", "NOK", "SEK", "DKK", "PLN", "NZD",
        "TRY", "ZAR", "THB", "MYR", "PHP", "IDR", "VND", "AED", "SAR", "ILS",
        "CLP", "ARS", "COP", "PEN", "UAH", "CZK", "HUF", "RON", "BGN", "HRK"
    ]
    
    init() {
        self.currency = UserDefaults.standard.string(forKey: "selectedCurrency") ?? "USD"
        let sortRaw = UserDefaults.standard.string(forKey: "defaultSortOrder") ?? "Date"
        self.defaultSortOrder = SortOrder(rawValue: sortRaw) ?? .date
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    }
}
