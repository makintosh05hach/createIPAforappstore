import CoreData
import Foundation

class PersistenceController: ObservableObject {
    static let shared = PersistenceController()
    
    let container: NSPersistentContainer
    
    @Published var errorMessage: String?
    @Published var hasError: Bool = false
    
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "ServiceModel")
        
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        
        container.loadPersistentStores { [weak self] description, error in
            if let error = error {
                print("Core Data failed to load: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self?.errorMessage = "Failed to load database: \(error.localizedDescription)"
                    self?.hasError = true
                }
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
    
    func save() throws {
        let context = container.viewContext
        
        guard context.hasChanges else { return }
        
        do {
            try context.save()
        } catch {
            let nsError = error as NSError
            print("Unresolved error \(nsError), \(nsError.userInfo)")
            throw PersistenceError.saveFailed(nsError.localizedDescription)
        }
    }
    
    enum PersistenceError: LocalizedError {
        case saveFailed(String)
        
        var errorDescription: String? {
            switch self {
            case .saveFailed(let message):
                return "Failed to save data: \(message)"
            }
        }
    }
}
