import SwiftUI

struct TemplatesSelectionView: View {
    let viewModel: ServicesViewModel
    let themeManager: ThemeManager
    let onSelect: (ServiceTemplate) -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(AppSettings.self) private var appSettings
    @State private var templates: [ServiceTemplate] = []
    
    var body: some View {
        ThemeView(themeManager: themeManager) { theme in
            NavigationStack {
                List {
                    if templates.isEmpty {
                        Text("No templates available")
                            .foregroundColor(theme.textColorValue.opacity(0.6))
                    } else {
                        ForEach(templates) { template in
                            Button {
                                onSelect(template)
                                dismiss()
                            } label: {
                                HStack {
                                    if let category = viewModel.categories.first(where: { $0.id == template.categoryId }) {
                                        Image(systemName: category.iconName ?? "folder.fill")
                                            .foregroundColor(Color(hex: category.colorName ?? "4A90E2"))
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(template.name)
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(theme.textColorValue)
                                        
                                        Text(PriceFormatter.format(template.price, currency: appSettings.currency))
                                            .font(.system(size: 14))
                                            .foregroundColor(theme.textColorValue.opacity(0.6))
                                    }
                                    
                                    Spacer()
                                }
                            }
                        }
                    }
                }
                .navigationTitle("Select Template")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                }
                .onAppear {
                    viewModel.loadData()
                    loadTemplates()
                }
            }
        }
    }
    
    private func loadTemplates() {
        if let data = UserDefaults.standard.data(forKey: "serviceTemplates"),
           let decoded = try? JSONDecoder().decode([ServiceTemplate].self, from: data) {
            templates = decoded
        }
    }
}
