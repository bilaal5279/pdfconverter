import SwiftUI
import StoreKit
import SafariServices

struct SettingsView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @Environment(\.dismiss) private var dismiss
    @Environment(\.requestReview) var requestReview
    @EnvironmentObject var subscriptionService: SubscriptionService
    
    // Support Email
    private let supportEmail = "info@digitalsprout.org"
    private let privacyURL = URL(string: "https://digitalsprout.org/pdfconverter/privacypolicy")!
    private let termsURL = URL(string: "https://digitalsprout.org/pdfconverter/terms-of-service")!
    private let appStoreURL = URL(string: "https://apps.apple.com/app/id6756530207")!
    
    @State private var activeSheet: ActiveSheet?
    @State private var showRestoreAlert = false
    @State private var restoreMessage = ""
    
    enum ActiveSheet: Identifiable {
        case privacy, terms
        var id: Int { hashValue }
    }
    
    var body: some View {
        ZStack {
            DesignSystem.Colors.background.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 32) {
                    
                    // Header
                    HStack(spacing: 16) {
                        Button(action: { dismiss() }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                                .frame(width: 44, height: 44) // Good touch target
                                .contentShape(Rectangle())
                        }
                        
                        Text("Settings")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    
                    // MARK: - Premium Section
                    VStack(alignment: .leading, spacing: 16) {
                        SectionHeader(title: "PRO MEMBERSHIP")
                        
                        Button(action: {
                            Task {
                                do {
                                    try await subscriptionService.restorePurchases()
                                    restoreMessage = subscriptionService.isPro ? "Purchases restored successfully!" : "No active subscription found."
                                    showRestoreAlert = true
                                } catch {
                                    restoreMessage = error.localizedDescription
                                    showRestoreAlert = true
                                }
                            }
                        }) {
                            MinimalRow(icon: "crown.fill", title: "Restore Purchases")
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // MARK: - Support Section
                    VStack(alignment: .leading, spacing: 16) {
                        SectionHeader(title: "SUPPORT")
                        
                        Button(action: {
                            requestReview()
                        }) {
                            MinimalRow(icon: "star.fill", title: "Rate Us")
                        }
                        
                        Link(destination: URL(string: "mailto:\(supportEmail)")!) {
                            MinimalRow(icon: "envelope.fill", title: "Contact Us")
                        }
                        
                        ShareLink(item: appStoreURL) {
                            MinimalRow(icon: "square.and.arrow.up.fill", title: "Share App")
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // MARK: - Legal Section
                    VStack(alignment: .leading, spacing: 16) {
                        SectionHeader(title: "LEGAL")
                        
                        Button(action: { activeSheet = .terms }) {
                            MinimalRow(icon: "doc.text.fill", title: "Terms of Service")
                        }
                        
                        Button(action: { activeSheet = .privacy }) {
                            MinimalRow(icon: "hand.raised.fill", title: "Privacy Policy")
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // MARK: - Developer Section
#if DEBUG
                    VStack(alignment: .leading, spacing: 16) {
                        SectionHeader(title: "DEVELOPER")
                        
                        Button(action: {
                            hasSeenOnboarding = false
                            dismiss()
                        }) {
                            MinimalRow(icon: "arrow.counterclockwise", title: "Reset Onboarding", isDestructive: true)
                        }
                    }
                    .padding(.horizontal, 20)
#endif
                    
                    // Footer
                    VStack(spacing: 6) {
                        Text("PDF Convert & PhotoScan")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Version 1.0.0")
                            .font(.system(size: 13, weight: .regular))
                    }
                    .foregroundColor(DesignSystem.Colors.textSecondary.opacity(0.6))
                    .padding(.top, 40)
                    .padding(.bottom, 60)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .privacy:
                SafariView(url: privacyURL)
                    .ignoresSafeArea()
            case .terms:
                SafariView(url: termsURL)
                    .ignoresSafeArea()
            }
        }
        .alert("Restore Purchases", isPresented: $showRestoreAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(restoreMessage)
        }
    }
}

// MARK: - Components

struct SectionHeader: View {
    let title: String
    
    var body: some View {
        Text(title)
            .font(.system(size: 12, weight: .bold))
            .foregroundColor(DesignSystem.Colors.textSecondary.opacity(0.7))
            .tracking(1)
    }
}

struct MinimalRow: View {
    let icon: String
    let title: String
    var isDestructive: Bool = false
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(isDestructive ? .red : DesignSystem.Colors.textPrimary)
                .frame(width: 24, alignment: .center)
            
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(isDestructive ? .red : DesignSystem.Colors.textPrimary)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(DesignSystem.Colors.textSecondary.opacity(0.3))
        }
        .padding(16)
        .background(DesignSystem.Colors.secondaryBackground)
        .cornerRadius(12)
        // Subtle Border instead of shadow for clean minimal look
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
        )
    }
}

struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let configuration = SFSafariViewController.Configuration()
        return SFSafariViewController(url: url, configuration: configuration)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
