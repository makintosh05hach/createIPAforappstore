import SwiftUI

struct CategoryFormView: View {
    @Environment(\.dismiss) private var dismiss
    let viewModel: ServicesViewModel
    let themeManager: ThemeManager
    let category: Category?
    
    @State private var name = ""
    @State private var selectedIcon = "folder.fill"
    @State private var selectedColor = "4A90E2"
    
    let icons = [
        "scissors", "car.fill", "briefcase.fill", "person.fill", "house.fill",
        "wrench.and.screwdriver.fill", "paintbrush.fill", "bandage.fill",
        "book.fill", "gamecontroller.fill", "camera.fill", "music.note",
        "heart.fill", "leaf.fill", "flame.fill", "bolt.fill", "star.fill",
        "moon.fill", "sun.max.fill", "cloud.fill", "drop.fill", "sparkles",
        "gift.fill", "cart.fill", "creditcard.fill", "dollarsign.circle.fill",
        "tag.fill", "ticket.fill", "bell.fill", "envelope.fill", "phone.fill",
        "message.fill", "paperplane.fill", "location.fill", "map.fill",
        "calendar", "clock.fill", "timer", "hourglass", "chart.bar.fill",
        "chart.line.uptrend.xyaxis", "percent", "number", "textformat",
        "pencil", "pencil.tip", "eraser.fill", "highlighter", "paperclip",
        "folder.fill", "doc.fill", "doc.text.fill", "list.bullet",
        "square.and.pencil", "checkmark.circle.fill", "xmark.circle.fill",
        "plus.circle.fill", "minus.circle.fill", "arrow.right.circle.fill"
    ]
    
    let colors = [
        "4A90E2", "27AE60", "FF6B6B", "F39C12", "9B7EDE",
        "E8B4B8", "48C9B0", "FF7F7F", "87A96B", "5D6D7E"
    ]
    
    init(viewModel: ServicesViewModel, themeManager: ThemeManager, category: Category?) {
        self.viewModel = viewModel
        self.themeManager = themeManager
        self.category = category
    }
    
    var body: some View {
        ThemeView(themeManager: themeManager) { theme in
            NavigationStack {
                Form {
                Section("Category Name") {
                    TextField("Category name", text: $name)
                }
                
                Section("Icon") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 20) {
                        ForEach(icons, id: \.self) { icon in
                            Button {
                                selectedIcon = icon
                            } label: {
                                Image(systemName: icon)
                                    .font(.system(size: 24))
                                    .foregroundColor(selectedIcon == icon ? Color(hex: selectedColor) : .gray)
                                    .frame(width: 44, height: 44)
                                    .background(selectedIcon == icon ? Color(hex: selectedColor).opacity(0.1) : Color.clear)
                                    .cornerRadius(10)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 10)
                }
                
                Section("Color") {
                    HStack(spacing: 15) {
                        ForEach(colors, id: \.self) { color in
                            Button {
                                selectedColor = color
                            } label: {
                                Circle()
                                    .fill(Color(hex: color))
                                    .frame(width: 44, height: 44)
                                    .overlay(
                                        Circle()
                                            .stroke(selectedColor == color ? Color.primary : Color.clear, lineWidth: 3)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 10)
                }
            }
                .navigationTitle(category == nil ? "New Category" : "Edit Category")
                .navigationBarTitleDisplayMode(.inline)
                .preferredColorScheme(theme.id == "dark" ? .dark : (theme.id == "light" ? .light : nil))
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                    
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            saveCategory()
                        }
                        .disabled(name.isEmpty)
                    }
                }
                .onAppear {
                    if let category = category {
                        loadCategory(category)
                    }
                }
            }
            .background(theme.backgroundColorValue)
        }
    }
    
    private func loadCategory(_ category: Category) {
        name = category.name ?? ""
        selectedIcon = category.iconName ?? "folder.fill"
        selectedColor = category.colorName ?? "4A90E2"
    }
    
    private func saveCategory() {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            // Could show error alert
            return
        }
        
        do {
            if let category = category {
                try viewModel.updateCategory(category, name: name, iconName: selectedIcon, colorName: selectedColor)
            } else {
                try viewModel.addCategory(name: name, iconName: selectedIcon, colorName: selectedColor)
            }
            dismiss()
        } catch {
            print("Failed to save category: \(error.localizedDescription)")
            // Could show error alert
        }
    }
}
