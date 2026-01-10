import SwiftUI
import NimbleViews

// MARK: - Modern Install/Modify Dialog
struct InstallModifyDialogView: View {
	@Environment(\.dismiss) var dismiss
	let app: AppInfoPresentable
	
	@State private var showInstallPreview = false
	@State private var animateSuccess = false
	
	var body: some View {
		ZStack {
			// Background gradient
			LinearGradient(
				colors: [
					Color.green.opacity(0.08),
					Color(.systemBackground)
				],
				startPoint: .top,
				endPoint: .center
			)
			.ignoresSafeArea()
			
			VStack(spacing: 0) {
				// Drag indicator
				Capsule()
					.fill(Color.secondary.opacity(0.3))
					.frame(width: 36, height: 5)
					.padding(.top, 8)
				
				// Success header
				VStack(spacing: 16) {
					// Animated success icon with rings
					ZStack {
						// Outer pulse ring
						Circle()
							.stroke(Color.green.opacity(0.2), lineWidth: 2)
							.frame(width: 90, height: 90)
							.scaleEffect(animateSuccess ? 1.2 : 1.0)
							.opacity(animateSuccess ? 0 : 0.5)
						
						// Middle ring
						Circle()
							.stroke(Color.green.opacity(0.3), lineWidth: 3)
							.frame(width: 70, height: 70)
						
						// Inner filled circle
						Circle()
							.fill(
								LinearGradient(
									colors: [Color.green, Color.green.opacity(0.8)],
									startPoint: .topLeading,
									endPoint: .bottomTrailing
								)
							)
							.frame(width: 56, height: 56)
							.shadow(color: Color.green.opacity(0.4), radius: 12, x: 0, y: 4)
						
						Image(systemName: "checkmark")
							.font(.system(size: 28, weight: .bold))
							.foregroundStyle(.white)
					}
					.onAppear {
						withAnimation(.easeOut(duration: 1.5).repeatForever(autoreverses: false)) {
							animateSuccess = true
						}
					}
					
					VStack(spacing: 6) {
						Text("Download Complete")
							.font(.system(size: 22, weight: .bold, design: .rounded))
							.foregroundStyle(.primary)
						
						Text("Choose an action for your app")
							.font(.system(size: 14, weight: .medium))
							.foregroundStyle(.secondary)
					}
				}
				.padding(.top, 24)
				.padding(.bottom, 20)
				
				// App info card - compact
				appInfoCard
					.padding(.horizontal, 20)
					.padding(.bottom, 20)
				
				// Action buttons - modern style
				VStack(spacing: 10) {
					// Sign & Install button - primary action
					Button {
						dismiss()
						DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
							showInstallPreview = true
						}
					} label: {
						HStack(spacing: 10) {
							Image(systemName: "arrow.down.app.fill")
								.font(.system(size: 18, weight: .semibold))
							Text("Sign & Install")
								.font(.system(size: 16, weight: .bold))
						}
						.foregroundStyle(.white)
						.frame(maxWidth: .infinity)
						.padding(.vertical, 14)
						.background(
							LinearGradient(
								colors: [Color.green, Color.green.opacity(0.85)],
								startPoint: .leading,
								endPoint: .trailing
							)
						)
						.clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
						.shadow(color: Color.green.opacity(0.3), radius: 8, x: 0, y: 4)
					}
					
					// Secondary actions row
					HStack(spacing: 10) {
						// Modify button
						Button {
							dismiss()
							DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
								NotificationCenter.default.post(
									name: Notification.Name("Feather.openSigningView"),
									object: app
								)
							}
						} label: {
							HStack(spacing: 6) {
								Image(systemName: "slider.horizontal.3")
									.font(.system(size: 14, weight: .semibold))
								Text("Modify")
									.font(.system(size: 14, weight: .semibold))
							}
							.foregroundStyle(.white)
							.frame(maxWidth: .infinity)
							.padding(.vertical, 12)
							.background(Color.accentColor)
							.clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
						}
						
						// Later button
						Button {
							dismiss()
						} label: {
							HStack(spacing: 6) {
								Image(systemName: "clock")
									.font(.system(size: 14, weight: .semibold))
								Text("Later")
									.font(.system(size: 14, weight: .semibold))
							}
							.foregroundStyle(.primary)
							.frame(maxWidth: .infinity)
							.padding(.vertical, 12)
							.background(Color(.secondarySystemGroupedBackground))
							.clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
						}
					}
				}
				.padding(.horizontal, 20)
				.padding(.bottom, 24)
			}
		}
		.sheet(isPresented: $showInstallPreview) {
			InstallPreviewView(app: app, isSharing: false, fromLibraryTab: false)
		}
	}
	
	// MARK: - App Info Card
	@ViewBuilder
	private var appInfoCard: some View {
		HStack(spacing: 12) {
			// App icon
			if let iconURL = (app as? Signed)?.iconURL ?? (app as? Imported)?.iconURL {
				AsyncImage(url: iconURL) { phase in
					switch phase {
					case .empty:
						iconPlaceholder
					case .success(let image):
						image
							.resizable()
							.aspectRatio(contentMode: .fill)
							.frame(width: 48, height: 48)
							.clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
					case .failure:
						iconPlaceholder
					@unknown default:
						iconPlaceholder
					}
				}
			} else {
				iconPlaceholder
			}
			
			// App info
			VStack(alignment: .leading, spacing: 3) {
				Text(app.name ?? "Unknown")
					.font(.system(size: 15, weight: .semibold))
					.foregroundStyle(.primary)
					.lineLimit(1)
				
				HStack(spacing: 8) {
					if let version = app.version {
						Label(version, systemImage: "number")
							.font(.system(size: 11, weight: .medium))
							.foregroundStyle(.secondary)
					}
					
					if let size = (app as? Signed)?.size ?? (app as? Imported)?.size {
						Label(size.formattedByteCount, systemImage: "internaldrive")
							.font(.system(size: 11, weight: .medium))
							.foregroundStyle(.secondary)
					}
				}
				.labelStyle(.titleOnly)
			}
			
			Spacer()
			
			// Ready badge
			Text("Ready")
				.font(.system(size: 10, weight: .bold))
				.foregroundStyle(.green)
				.padding(.horizontal, 8)
				.padding(.vertical, 4)
				.background(Color.green.opacity(0.15))
				.clipShape(Capsule())
		}
		.padding(12)
		.background(
			RoundedRectangle(cornerRadius: 14, style: .continuous)
				.fill(Color(.secondarySystemGroupedBackground))
		)
	}
	
	private var iconPlaceholder: some View {
		RoundedRectangle(cornerRadius: 11, style: .continuous)
			.fill(Color.secondary.opacity(0.15))
			.frame(width: 48, height: 48)
			.overlay(
				Image(systemName: "app.fill")
					.font(.system(size: 20))
					.foregroundStyle(.secondary)
			)
	}
}
