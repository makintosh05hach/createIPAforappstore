import SwiftUI

extension View {
    func theme(_ themeManager: ThemeManager, colorScheme: ColorScheme) -> AppTheme {
        themeManager.resolvedTheme(colorScheme: colorScheme)
    }
}
