import SwiftUI
import UIKit

struct ServiceDetailView: View {
    let service: Service
    let viewModel: ServicesViewModel
    let themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    @State private var showEditForm = false
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Photo
                if let photoData = service.photoData,
                   let uiImage = UIImage(data: photoData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 300)
                        .clipped()
                        .cornerRadius(24)
                        .padding(.horizontal, 20)
                }
                
                VStack(alignment: .leading, spacing: 20) {
                    // Title and Price
                    VStack(alignment: .leading, spacing: 8) {
                        Text(service.name ?? "Unnamed Service")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(themeManager.currentTheme.textColorValue)
                        
                        Text(PriceFormatter.format(service.price, currency: service.currency ?? "USD"))
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundColor(themeManager.currentTheme.accentColorValue)
                    }
                    
                    // Date
                    if let date = service.date {
                        HStack {
                            Image(systemName: "calendar")
                            Text(date, style: .date)
                        }
                        .font(.system(size: 16))
                        .foregroundColor(themeManager.currentTheme.textColorValue.opacity(0.7))
                    }
                    
                    // Provider
                    if let provider = service.provider, !provider.isEmpty {
                        HStack {
                            Image(systemName: "person.fill")
                            Text(provider)
                        }
                        .font(.system(size: 16))
                        .foregroundColor(themeManager.currentTheme.textColorValue.opacity(0.7))
                    }
                    
                    // Location
                    if let location = service.location, !location.isEmpty {
                        HStack {
                            Image(systemName: "location.fill")
                            Text(location)
                        }
                        .font(.system(size: 16))
                        .foregroundColor(themeManager.currentTheme.textColorValue.opacity(0.7))
                    }
                    
                    // Average comparison
                    if let category = service.category {
                        let average = viewModel.averagePriceInCategory(category)
                        if average > 0 {
                            let difference = service.price - average
                            let currency = service.currency ?? "USD"
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Average in category: \(PriceFormatter.format(average, currency: currency))")
                                    .font(.system(size: 16, weight: .medium))
                                
                                if abs(difference) < 0.01 {
                                    Text("You paid the average price")
                                        .font(.system(size: 14))
                                        .foregroundColor(.gray)
                                } else if difference < 0 {
                                    HStack {
                                        Image(systemName: "arrow.down.circle.fill")
                                            .foregroundColor(.green)
                                        Text("You paid \(PriceFormatter.format(abs(difference), currency: currency)) less — good deal!")
                                            .foregroundColor(.green)
                                    }
                                    .font(.system(size: 14))
                                } else {
                                    HStack {
                                        Image(systemName: "arrow.up.circle.fill")
                                            .foregroundColor(.orange)
                                        Text("You paid \(PriceFormatter.format(difference, currency: currency)) more")
                                            .foregroundColor(.orange)
                                    }
                                    .font(.system(size: 14))
                                }
                            }
                            .padding()
                            .background(themeManager.currentTheme.cardColorValue)
                            .cornerRadius(16)
                        }
                    }
                    
                    // Note
                    if let note = service.note, !note.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Notes")
                                .font(.system(size: 18, weight: .semibold))
                            Text(note)
                                .font(.system(size: 16))
                        }
                        .padding()
                        .background(themeManager.currentTheme.cardColorValue)
                        .cornerRadius(16)
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.vertical, 20)
        }
        .background(themeManager.currentTheme.backgroundColorValue)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(themeManager.currentTheme.id == "dark" ? .dark : (themeManager.currentTheme.id == "light" ? .light : nil), for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        do {
                            try viewModel.toggleFavorite(service)
                        } catch {
                            print("Failed to toggle favorite: \(error.localizedDescription)")
                        }
                    } label: {
                        Label(service.isFavorite ? "Remove from Favorites" : "Add to Favorites", systemImage: service.isFavorite ? "star.fill" : "star")
                    }
                    
                    Button {
                        do {
                            try viewModel.duplicateService(service)
                        } catch {
                            print("Failed to duplicate service: \(error.localizedDescription)")
                        }
                    } label: {
                        Label("Duplicate", systemImage: "doc.on.doc")
                    }
                    
                    Button {
                        showEditForm = true
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    
                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showEditForm) {
            ServiceFormView(
                viewModel: viewModel,
                themeManager: themeManager,
                service: service
            )
        }
        .alert("Delete Service", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                do {
                    try viewModel.deleteService(service)
                    dismiss()
                } catch {
                    print("Failed to delete service: \(error.localizedDescription)")
                }
            }
        } message: {
            Text("Are you sure you want to delete this service? This action cannot be undone.")
        }
    }
    
}
