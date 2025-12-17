import SwiftUI

struct MainTabView: View {
    @State private var themeManager = ThemeManager()
    @State private var appSettings = AppSettings()
    @State private var viewModel: ServicesViewModel
    
    init() {
        let context = PersistenceController.shared.container.viewContext
        _viewModel = State(initialValue: ServicesViewModel(context: context))
    }
    
    var body: some View {
        ThemeView(themeManager: themeManager) { theme in
            TabView {
                DashboardView(themeManager: themeManager)
                    .tabItem {
                        Label("Home", systemImage: "house.fill")
                    }
                
                FavoritesView(viewModel: viewModel, themeManager: themeManager)
                    .tabItem {
                        Label("Favorites", systemImage: "star.fill")
                    }
                
                HistoryView(viewModel: viewModel, themeManager: themeManager)
                    .tabItem {
                        Label("History", systemImage: "clock.fill")
                    }
                
                StatisticsView(viewModel: viewModel, themeManager: themeManager)
                    .tabItem {
                        Label("Stats", systemImage: "chart.bar.fill")
                    }
                
                MoreView(viewModel: viewModel, themeManager: themeManager, appSettings: appSettings)
                    .tabItem {
                        Label("More", systemImage: "ellipsis.circle.fill")
                    }
            }
            .preferredColorScheme(theme.id == "dark" ? .dark : (theme.id == "light" ? .light : nil))
            .environment(appSettings)
        }
    }
}
