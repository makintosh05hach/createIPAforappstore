import SwiftUI

@main
struct Project_16_12_25_2App: App {
    @State private var persistenceController = PersistenceController.shared
    @State private var showSplash = true
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if showSplash {
                    SplashScreenView {
                        showSplash = false
                    }
                } else {
                    MainTabView()
                        .environment(\.managedObjectContext, persistenceController.container.viewContext)
                }
            }
        }
    }
}
