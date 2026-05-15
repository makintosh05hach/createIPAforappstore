import SwiftUI

struct AppTheme: Identifiable, Codable {
    let id: String
    let name: String
    let primaryColor: String
    let secondaryColor: String
    let backgroundColor: String
    let cardColor: String
    let textColor: String
    let accentColor: String
    
    var primaryColorValue: Color {
        Color(hex: primaryColor)
    }
    
    var secondaryColorValue: Color {
        Color(hex: secondaryColor)
    }
    
    var backgroundColorValue: Color {
        Color(hex: backgroundColor)
    }
    
    var cardColorValue: Color {
        Color(hex: cardColor)
    }
    
    var textColorValue: Color {
        Color(hex: textColor)
    }
    
    var accentColorValue: Color {
        Color(hex: accentColor)
    }
    
    static let lightTheme = AppTheme(
        id: "light",
        name: "Light",
        primaryColor: "4A90E2",
        secondaryColor: "27AE60",
        backgroundColor: "FFFFFF",
        cardColor: "F8F9FA",
        textColor: "1A1A1A",
        accentColor: "4A90E2"
    )
    
    static let darkTheme = AppTheme(
        id: "dark",
        name: "Dark",
        primaryColor: "5B9BD5",
        secondaryColor: "6CBF47",
        backgroundColor: "1E1E1E",
        cardColor: "2C2C2E",
        textColor: "FFFFFF",
        accentColor: "5B9BD5"
    )
    
    static let allThemes: [AppTheme] = [
        AppTheme(
            id: "auto",
            name: "Automatic",
            primaryColor: "4A90E2",
            secondaryColor: "27AE60",
            backgroundColor: "FFFFFF",
            cardColor: "F8F9FA",
            textColor: "1A1A1A",
            accentColor: "4A90E2"
        ),
        lightTheme,
        darkTheme
    ]
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
