import CoreData

// MARK: - Class extension: Imported Apps
extension Storage {
	/// Notification posted when a new app is added to the library
	static let appDidAddNotification = Notification.Name("Feather.appDidAdd")
	
	func addImported(
		uuid: String,
		source: URL? = nil,
		appName: String? = nil,
		appIdentifier: String? = nil,
		appVersion: String? = nil,
		appIcon: String? = nil,
		completion: @escaping (Error?) -> Void
	) {
		DispatchQueue.main.async { [weak self] in
			guard let self = self else {
				completion(NSError(domain: "Storage", code: -1, userInfo: [NSLocalizedDescriptionKey: "Storage instance deallocated"]))
				return
			}
			
			let new = Imported(context: self.context)
			
			new.uuid = uuid
			new.source = source
			new.date = Date()
			new.identifier = appIdentifier ?? ""
			new.name = appName ?? "Unknown"
			new.icon = appIcon
			new.version = appVersion ?? ""
			
			do {
				// Force save even if hasChanges might be false due to timing
				try self.context.save()
				
				// Ensure the context processes pending changes
				self.context.processPendingChanges()
				
				HapticsManager.shared.impact()
				AppLogManager.shared.success("Successfully added imported app to database: \(appName ?? "Unknown")", category: "Storage")
				
				// Post notification that app was added - this helps trigger UI updates
				NotificationCenter.default.post(
					name: Storage.appDidAddNotification,
					object: nil,
					userInfo: ["uuid": uuid, "name": appName ?? "Unknown"]
				)
				
				completion(nil)
			} catch {
				AppLogManager.shared.error("Failed to save imported app to database: \(error.localizedDescription)", category: "Storage")
				completion(error)
			}
		}
	}
	
	func getLatestImportedApp() -> Imported? {
		let fetchRequest: NSFetchRequest<Imported> = Imported.fetchRequest()
		fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Imported.date, ascending: false)]
		fetchRequest.fetchLimit = 1
		return (try? context.fetch(fetchRequest))?.first
	}
	
	func getAllImportedApps() -> [Imported] {
		let fetchRequest: NSFetchRequest<Imported> = Imported.fetchRequest()
		fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Imported.date, ascending: false)]
		return (try? context.fetch(fetchRequest)) ?? []
	}
}
