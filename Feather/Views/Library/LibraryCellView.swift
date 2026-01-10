import SwiftUI
import NimbleExtensions
import NimbleViews

// MARK: - LibraryCellView - Pure SwiftUI cell for app display
struct LibraryCellView: View {
	@Environment(\.horizontalSizeClass) private var horizontalSizeClass
	@Environment(\.editMode) private var editMode

	// MARK: - Properties bound to model
	let app: AppInfoPresentable
	@Binding var selectedInfoAppPresenting: AnyApp?
	@Binding var selectedSigningAppPresenting: AnyApp?
	@Binding var selectedInstallAppPresenting: AnyApp?
	@Binding var selectedAppUUIDs: Set<String>
	
	// MARK: - Computed properties from model
	private var certInfo: Date.ExpirationInfo? {
		Storage.shared.getCertificate(from: app)?.expiration?.expirationInfo()
	}
	
	private var certRevoked: Bool {
		Storage.shared.getCertificate(from: app)?.revoked == true
	}
	
	private var appName: String {
		app.name ?? .localized("Unknown")
	}
	
	private var appDescription: String {
		if let version = app.version, let id = app.identifier {
			return "\(version) • \(id)"
		} else {
			return .localized("Unknown")
		}
	}
	
	private var isSelected: Bool {
		guard let uuid = app.uuid else { return false }
		return selectedAppUUIDs.contains(uuid)
	}
	
	// MARK: - Body
	var body: some View {
		let isRegular = horizontalSizeClass != .compact
		let isEditing = editMode?.wrappedValue == .active
		
		HStack(spacing: 16) {
			// Selection checkbox in edit mode
			if isEditing {
				selectionButton
			}
			
			// App icon - always visible
			appIcon
			
			// App info text
			appInfoStack
			
			// Action button when not editing
			if !isEditing {
				actionButton
			}
		}
		.padding(isRegular ? 12 : 8)
		.frame(minHeight: 68)
		.background(cellBackground(isRegular: isRegular, isEditing: isEditing))
		.contentShape(Rectangle())
		.onTapGesture {
			handleTap(isEditing: isEditing)
		}
		.swipeActions(edge: .trailing, allowsFullSwipe: true) {
			if !isEditing {
				deleteAction
			}
		}
		.contextMenu {
			if !isEditing {
				contextMenuContent
			}
		}
	}
	
	// MARK: - View Components
	@ViewBuilder
	private var selectionButton: some View {
		Button {
			toggleSelection()
		} label: {
			Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
				.foregroundColor(isSelected ? .accentColor : .secondary)
				.font(.title2)
		}
		.buttonStyle(.borderless)
	}
	
	@ViewBuilder
	private var appIcon: some View {
		FRAppIconView(app: app, size: 52)
			.clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
			.shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
	}
	
	@ViewBuilder
	private var appInfoStack: some View {
		VStack(alignment: .leading, spacing: 3) {
			Text(appName)
				.font(.system(size: 16, weight: .semibold))
				.foregroundStyle(.primary)
				.lineLimit(1)
			
			Text(appDescription)
				.font(.system(size: 13))
				.foregroundStyle(.secondary)
				.lineLimit(1)
			
			if app.isSigned {
				HStack(spacing: 4) {
					Image(systemName: "checkmark.seal.fill")
						.font(.system(size: 10))
						.foregroundStyle(.green)
					Text("Signed")
						.font(.system(size: 11, weight: .medium))
						.foregroundStyle(.green)
				}
			}
		}
		.frame(maxWidth: .infinity, alignment: .leading)
	}
	
	@ViewBuilder
	private var actionButton: some View {
		Button {
			if app.isSigned {
				selectedInstallAppPresenting = AnyApp(base: app)
			} else {
				selectedSigningAppPresenting = AnyApp(base: app)
			}
		} label: {
			FRExpirationPillView(
				title: app.isSigned ? .localized("Install") : .localized("Sign"),
				revoked: certRevoked,
				expiration: certInfo
			)
		}
		.buttonStyle(.borderless)
	}
	
	@ViewBuilder
	private var deleteAction: some View {
		Button(role: .destructive) {
			Storage.shared.deleteApp(for: app)
		} label: {
			Label(.localized("Delete"), systemImage: "trash")
		}
	}
	
	@ViewBuilder
	private var contextMenuContent: some View {
		// Info action
		Button {
			selectedInfoAppPresenting = AnyApp(base: app)
		} label: {
			Label(.localized("Get Info"), systemImage: "info.circle")
		}
		
		Divider()
		
		// App-specific actions
		if app.isSigned {
			if let id = app.identifier {
				Button {
					UIApplication.openApp(with: id)
				} label: {
					Label(.localized("Open"), systemImage: "app.badge.checkmark")
				}
			}
			Button {
				selectedInstallAppPresenting = AnyApp(base: app)
			} label: {
				Label(.localized("Install"), systemImage: "square.and.arrow.down")
			}
			Button {
				selectedSigningAppPresenting = AnyApp(base: app)
			} label: {
				Label(.localized("Re-sign"), systemImage: "signature")
			}
			Button {
				selectedInstallAppPresenting = AnyApp(base: app, archive: true)
			} label: {
				Label(.localized("Export"), systemImage: "square.and.arrow.up")
			}
		} else {
			Button {
				selectedInstallAppPresenting = AnyApp(base: app)
			} label: {
				Label(.localized("Install"), systemImage: "square.and.arrow.down")
			}
			Button {
				selectedSigningAppPresenting = AnyApp(base: app)
			} label: {
				Label(.localized("Sign"), systemImage: "signature")
			}
		}
		
		Divider()
		
		// Delete action
		Button(role: .destructive) {
			Storage.shared.deleteApp(for: app)
		} label: {
			Label(.localized("Delete"), systemImage: "trash")
		}
	}
	
	// MARK: - Helper Methods
	@ViewBuilder
	private func cellBackground(isRegular: Bool, isEditing: Bool) -> some View {
		if isRegular {
			RoundedRectangle(cornerRadius: 16, style: .continuous)
				.fill(isSelected && isEditing ? Color.accentColor.opacity(0.1) : Color(uiColor: .secondarySystemGroupedBackground))
		}
	}
	
	private func handleTap(isEditing: Bool) {
		if isEditing {
			toggleSelection()
		} else {
			selectedInfoAppPresenting = AnyApp(base: app)
		}
	}
	
	private func toggleSelection() {
		guard let uuid = app.uuid else { return }
		if selectedAppUUIDs.contains(uuid) {
			selectedAppUUIDs.remove(uuid)
		} else {
			selectedAppUUIDs.insert(uuid)
		}
	}
}