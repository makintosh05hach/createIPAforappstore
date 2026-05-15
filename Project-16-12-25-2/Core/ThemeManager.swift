import SwiftUI

@Observable
class ThemeManager {
    var currentTheme: AppTheme {
        didSet {
            saveTheme()
        }
    }
    
    init() {
        let savedThemeId = UserDefaults.standard.string(forKey: "selectedThemeId") ?? "auto"
        if let theme = AppTheme.allThemes.first(where: { $0.id == savedThemeId }) {
            self.currentTheme = theme
        } else {
            self.currentTheme = AppTheme.allThemes[0] // Automatic
        }
    }
    
    private func saveTheme() {
        UserDefaults.standard.set(currentTheme.id, forKey: "selectedThemeId")
    }
    
    func setTheme(_ theme: AppTheme) {
        currentTheme = theme
    }
    
    func resolvedTheme(colorScheme: ColorScheme) -> AppTheme {
        if currentTheme.id == "auto" {
            return colorScheme == .dark ? AppTheme.darkTheme : AppTheme.lightTheme
        }
        return currentTheme
    }
}
