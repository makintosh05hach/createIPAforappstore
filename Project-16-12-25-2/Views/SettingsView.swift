import SwiftUI
import UIKit
import CoreData
import UniformTypeIdentifiers

struct SettingsView: View {
    let viewModel: ServicesViewModel
    let themeManager: ThemeManager
    @Bindable var appSettings: AppSettings
    @State private var showThemePicker = false
    @State private var showCurrencyPicker = false
    @State private var showResetConfirmation = false
    @State private var resetConfirmationCount = 0
    @State private var showDocumentPicker = false
    @Environment(\.managedObjectContext) private var viewContext
    
    var body: some View {
        ThemeView(themeManager: themeManager) { theme in
            NavigationStack {
                Form {
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
                
                Section("Backup & Restore") {
                    Button {
                        createBackup()
                    } label: {
                        HStack {
                            Image(systemName: "icloud.and.arrow.up")
                            Text("Create Backup")
                        }
                    }
                    
                    Button {
                        restoreBackup()
                    } label: {
                        HStack {
                            Image(systemName: "icloud.and.arrow.down")
                            Text("Restore from Backup")
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
                .navigationTitle("Settings")
                .navigationBarTitleDisplayMode(.large)
                .preferredColorScheme(theme.id == "dark" ? .dark : (theme.id == "light" ? .light : nil))
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
            .background(theme.backgroundColorValue)
        }
    }
    
    private func createBackup() {
        let backupURL = BackupManager.createBackup(
            services: viewModel.services,
            categories: viewModel.categories
        )
        
        if let url = backupURL {
            let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
            
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
    
    private func exportData() {
        let pdfURL = PDFExporter.generatePDF(
            services: viewModel.services,
            categories: viewModel.categories,
            currency: appSettings.currency
        )
        
        if let url = pdfURL {
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
    }
    
    private func exportCSV() {
        let csvURL = CSVExporter.generateCSV(
            services: viewModel.services,
            categories: viewModel.categories
        )
        
        if let url = csvURL {
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
            print("Failed to reset data: \(error)")
        }
    }
}

struct ThemePickerView: View {
    let themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(AppTheme.allThemes) { theme in
                    Button {
                        themeManager.setTheme(theme)
                        dismiss()
                    } label: {
                        HStack {
                            Circle()
                                .fill(theme.primaryColorValue)
                                .frame(width: 30, height: 30)
                            
                            Text(theme.name)
                            
                            Spacer()
                            
                            if themeManager.currentTheme.id == theme.id {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Theme")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct CurrencyPickerView: View {
    let appSettings: AppSettings
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(AppSettings.availableCurrencies, id: \.self) { currency in
                    Button {
                        appSettings.currency = currency
                        dismiss()
                    } label: {
                        HStack {
                            Text(currency)
                            
                            Spacer()
                            
                            if appSettings.currency == currency {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Currency")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
