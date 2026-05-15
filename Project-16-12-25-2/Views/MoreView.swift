import SwiftUI
import UIKit
import CoreData
import UniformTypeIdentifiers

struct MoreView: View {
    let viewModel: ServicesViewModel
    let themeManager: ThemeManager
    @Bindable var appSettings: AppSettings
    @State private var showThemePicker = false
    @State private var showCurrencyPicker = false
    @State private var showResetConfirmation = false
    @State private var resetConfirmationCount = 0
    @State private var showDocumentPicker = false
    @Environment(\.managedObjectContext) private var viewContext
    
    init(viewModel: ServicesViewModel, themeManager: ThemeManager, appSettings: AppSettings) {
        self.viewModel = viewModel
        self.themeManager = themeManager
        self.appSettings = appSettings
    }
    
    var body: some View {
        ThemeView(themeManager: themeManager) { theme in
            NavigationStack {
                Form {
                    Section("Tools") {
                        NavigationLink(destination: ComparisonView(viewModel: viewModel, themeManager: themeManager)) {
                            HStack {
                                Image(systemName: "square.grid.2x2")
                                    .foregroundColor(theme.accentColorValue)
                                Text("Compare Prices")
                            }
                        }
                        
                        NavigationLink(destination: BudgetView(viewModel: viewModel, themeManager: themeManager)) {
                            HStack {
                                Image(systemName: "chart.pie.fill")
                                    .foregroundColor(theme.accentColorValue)
                                Text("Budget Management")
                            }
                        }
                        
                        NavigationLink(destination: TemplatesView(viewModel: viewModel, themeManager: themeManager)) {
                            HStack {
                                Image(systemName: "doc.text.fill")
                                    .foregroundColor(theme.accentColorValue)
                                Text("Service Templates")
                            }
                        }
                        
                        NavigationLink(destination: RecurringServicesView(viewModel: viewModel, themeManager: themeManager)) {
                            HStack {
                                Image(systemName: "repeat.circle.fill")
                                    .foregroundColor(theme.accentColorValue)
                                Text("Recurring Services")
                            }
                        }
                        
                        NavigationLink(destination: ProvidersView(viewModel: viewModel, themeManager: themeManager)) {
                            HStack {
                                Image(systemName: "person.3.fill")
                                    .foregroundColor(theme.accentColorValue)
                                Text("Provider Ratings")
                            }
                        }
                        
                        NavigationLink(destination: PriceTrendsView(viewModel: viewModel, themeManager: themeManager)) {
                            HStack {
                                Image(systemName: "chart.line.uptrend.xyaxis")
                                    .foregroundColor(theme.accentColorValue)
                                Text("Price Trends")
                            }
                        }
                    }
                    
                    Section("Appearance") {
                        Button {
                            showThemePicker = true
                        } label: {
                            HStack {
                                Text("Theme")
                                Spacer()
                                Text(themeManager.currentTheme.name)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    Section("Currency") {
                        Button {
                            showCurrencyPicker = true
                        } label: {
                            HStack {
                                Text("Default Currency")
                                Spacer()
                                Text(appSettings.currency)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    Section("Sorting") {
                        Picker("Default Sort Order", selection: $appSettings.defaultSortOrder) {
                            ForEach(AppSettings.SortOrder.allCases, id: \.self) { order in
                                Text(order.rawValue).tag(order)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    
                    Section("Data Management") {
                        Button {
                            exportData()
                        } label: {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                Text("Export as PDF")
                            }
                        }
                        
                        Button {
                            exportCSV()
                        } label: {
                            HStack {
                                Image(systemName: "doc.text")
                                Text("Export as CSV")
                            }
                        }
                    }
                    
                    Section("Danger Zone") {
                        Button(role: .destructive) {
                            resetConfirmationCount += 1
                            if resetConfirmationCount >= 3 {
                                resetAllData()
                                resetConfirmationCount = 0
                            } else {
                                showResetConfirmation = true
                            }
                        } label: {
                            HStack {
                                Image(systemName: "trash")
                                Text("Reset All Data")
                            }
                        }
                    }
                    
                    Section("About") {
                        HStack {
                            Text("Version")
                            Spacer()
                            Text("1.0.0")
                                .foregroundColor(.secondary)
                        }
                        
                        Text("Personal Service Price List helps you track service prices you've paid, so you always know the fair cost in your city.")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                        
                        Text("100% Private & Offline")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.green)
                    }
                }
                .navigationTitle("More")
                .navigationBarTitleDisplayMode(.large)
                .toolbarColorScheme(theme.id == "dark" ? .dark : (theme.id == "light" ? .light : nil), for: .navigationBar)
                .sheet(isPresented: $showThemePicker) {
                    ThemePickerView(themeManager: themeManager)
                }
                .sheet(isPresented: $showCurrencyPicker) {
                    CurrencyPickerView(appSettings: appSettings)
                }
                .alert("Reset All Data", isPresented: $showResetConfirmation) {
                    Button("Cancel", role: .cancel) {
                        resetConfirmationCount = 0
                    }
                    Button("Reset", role: .destructive) {
                        // Continue counting
                    }
                } message: {
                    Text("This will delete all your services and categories. This action cannot be undone. Tap Reset \(3 - resetConfirmationCount) more time(s) to confirm.")
                }
                .fileImporter(
                    isPresented: $showDocumentPicker,
                    allowedContentTypes: [.json],
                    allowsMultipleSelection: false
                ) { result in
                    switch result {
                    case .success(let urls):
                        if let url = urls.first {
                            restoreFromBackup(url: url)
                        }
                    case .failure:
                        break
                    }
                }
            }
        }
    }
    
    private func exportData() {
        guard !viewModel.services.isEmpty else {
            // Could show alert: "No data to export"
            return
        }
        
        let pdfURL = PDFExporter.generatePDF(
            services: viewModel.services,
            categories: viewModel.categories,
            currency: appSettings.currency
        )
        
        guard let url = pdfURL else {
            // Could show error alert
            return
        }
        
        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            // For iPad
            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = rootViewController.view
                popover.sourceRect = CGRect(x: rootViewController.view.bounds.midX, y: rootViewController.view.bounds.midY, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }
            
            rootViewController.present(activityVC, animated: true)
        }
    }
    
    private func exportCSV() {
        guard !viewModel.services.isEmpty else {
            // Could show alert: "No data to export"
            return
        }
        
        let csvURL = CSVExporter.generateCSV(
            services: viewModel.services,
            categories: viewModel.categories
        )
        
        guard let url = csvURL else {
            // Could show error alert
            return
        }
        
        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            // For iPad
            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = rootViewController.view
                popover.sourceRect = CGRect(x: rootViewController.view.bounds.midX, y: rootViewController.view.bounds.midY, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }
            
            rootViewController.present(activityVC, animated: true)
        }
    }
    
    private func createBackup() {
        guard !viewModel.services.isEmpty || !viewModel.categories.isEmpty else {
            // Could show alert: "No data to backup"
            return
        }
        
        guard let backupURL = BackupManager.createBackup(
            services: viewModel.services,
            categories: viewModel.categories
        ) else {
            // Could show error alert
            return
        }
        
        let activityVC = UIActivityViewController(activityItems: [backupURL], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = rootViewController.view
                popover.sourceRect = CGRect(x: rootViewController.view.bounds.midX, y: rootViewController.view.bounds.midY, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }
            
            rootViewController.present(activityVC, animated: true)
        }
    }
    
    private func restoreBackup() {
        showDocumentPicker = true
    }
    
    private func restoreFromBackup(url: URL) {
        let success = BackupManager.restoreFromBackup(url: url, context: viewContext)
        
        if success {
            viewModel.loadData()
            // Show success alert
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let rootViewController = windowScene.windows.first?.rootViewController {
                    let alert = UIAlertController(title: "Success", message: "Backup restored successfully", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    rootViewController.present(alert, animated: true)
                }
            }
        } else {
            // Show error alert
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootViewController = windowScene.windows.first?.rootViewController {
                let alert = UIAlertController(title: "Error", message: "Failed to restore backup", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                rootViewController.present(alert, animated: true)
            }
        }
    }
    
    private func resetAllData() {
        let context = PersistenceController.shared.container.viewContext
        let serviceRequest: NSFetchRequest<NSFetchRequestResult> = Service.fetchRequest()
        let categoryRequest: NSFetchRequest<NSFetchRequestResult> = Category.fetchRequest()
        
        let serviceDelete = NSBatchDeleteRequest(fetchRequest: serviceRequest)
        let categoryDelete = NSBatchDeleteRequest(fetchRequest: categoryRequest)
        
        do {
            try context.execute(serviceDelete)
            try context.execute(categoryDelete)
            try context.save()
            viewModel.loadData()
        } catch {
            print("Failed to reset data: \(error.localizedDescription)")
            // Could show error alert to user
        }
    }
}
