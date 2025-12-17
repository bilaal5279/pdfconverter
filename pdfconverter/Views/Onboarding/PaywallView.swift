import SwiftUI
import RevenueCat
import SafariServices

struct PaywallView: View {
    @EnvironmentObject var subscriptionService: SubscriptionService
    @Environment(\.dismiss) var dismiss
    
    @State private var isPurchasing = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var activeSheet: ActiveSheet?
    @State private var isPulseAnimating = false
    
    enum ActiveSheet: Identifiable {
        case privacy, terms
        var id: Int { hashValue }
    }
    
    // Links
    private let privacyURL = URL(string: "https://digitalsprout.org/pdfconverter/privacypolicy")!
    private let termsURL = URL(string: "https://digitalsprout.org/pdfconverter/terms-of-service")!
    
    // iPad Helper
    private var isIpad: Bool {
        UIDevice.current.model.contains("iPad")
    }

    var body: some View {
        ZStack {
            // MARK: - Premium Background
            DesignSystem.Colors.background.ignoresSafeArea()
            
            // Atmospheric Mesh Gradient / Blobs
            ZStack {
                Circle()
                    .fill(DesignSystem.Colors.royalBlue.opacity(0.1))
                    .frame(width: 350, height: 350)
                    .blur(radius: 80)
                    .offset(x: -100, y: -250)
                
                Circle()
                    .fill(DesignSystem.Colors.metallicGold.opacity(0.08))
                    .frame(width: 300, height: 300)
                    .blur(radius: 70)
                    .offset(x: 120, y: 150)
            }
            .ignoresSafeArea()
            
            GeometryReader { geometry in
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // MARK: - Header / Icon
                        Spacer()
                            .frame(height: isIpad ? 10 : 40)
                        
                        ZStack {
                            Circle()
                                .fill(Color.white)
                                .frame(width: isIpad ? 70 : 100, height: isIpad ? 70 : 100)
                                .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: 10)
                            
                            Image(systemName: "crown.fill")
                                .font(.system(size: isIpad ? 32 : 44))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [DesignSystem.Colors.royalBlue, DesignSystem.Colors.royalBlue.opacity(0.7)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }
                        .padding(.bottom, isIpad ? 12 : 24)
                        
                        Text("Unlock Pro Access")
                            .font(.system(size: isIpad ? 24 : 32, weight: .bold))
                            .foregroundColor(DesignSystem.Colors.deepCharcoal)
                            .padding(.bottom, isIpad ? 2 : 8)
                        
                        Text("Get unlimited access to all features")
                            .font(.system(size: isIpad ? 13 : 16, weight: .medium))
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                            .padding(.bottom, isIpad ? 16 : 40)
                        
                        // MARK: - Features
                        VStack(spacing: isIpad ? 8 : 20) {
                            PremiumFeatureRow(icon: "doc.viewfinder", text: "Unlimited Scanning", isIpad: isIpad)
                            PremiumFeatureRow(icon: "text.viewfinder", text: "Advanced OCR (Text Recognition)", isIpad: isIpad)
                            PremiumFeatureRow(icon: "lock.shield", text: "Secure Cloud Sync", isIpad: isIpad)
                            PremiumFeatureRow(icon: "square.and.arrow.up", text: "Export in High Quality", isIpad: isIpad)
                            PremiumFeatureRow(icon: "xmark.circle", text: "Remove All Ads", isIpad: isIpad)
                        }
                        .padding(.horizontal, 32)
                        
                        Spacer()
                        
                        // MARK: - Pricing & CTA
                        VStack(spacing: isIpad ? 12 : 16) {
                            // Trial Badge
                            Text("3 DAYS FREE")
                                .font(.system(size: 11, weight: .bold))
                                .tracking(1.5)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(DesignSystem.Colors.royalBlue.opacity(0.1))
                                .foregroundColor(DesignSystem.Colors.royalBlue)
                                .clipShape(Capsule())
                            
                            // Offer Details
                            if let offer = subscriptionService.currentOffering?.availablePackages.first(where: { $0.identifier == "$rc_weekly" }) {
                                VStack(spacing: 4) {
                                    Text(offer.storeProduct.localizedPriceString + " / week")
                                        .font(.system(size: isIpad ? 18 : 22, weight: .bold))
                                        .foregroundColor(DesignSystem.Colors.textPrimary)
                                    
                                    // Reassurance Text moved closer to CTA
                                    Text("No commitment. Cancel anytime.")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(DesignSystem.Colors.textSecondary)
                                }
                                .padding(.bottom, isIpad ? 8 : 12)
                                
                                Button(action: {
                                    Task {
                                        await purchase(package: offer)
                                    }
                                }) {
                                    ZStack {
                                        if isPurchasing {
                                            ProgressView()
                                                .tint(.white)
                                        } else {
                                            Text("Start Free Trial Now")
                                                .font(.system(size: 20, weight: .bold)) // Slightly Larger
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: isIpad ? 48 : 56)
                                    .background(DesignSystem.Colors.royalBlue)
                                    .foregroundColor(.white)
                                    .cornerRadius(16)
                                    .shadow(color: DesignSystem.Colors.royalBlue.opacity(0.4), radius: 15, x: 0, y: 8)
                                    .scaleEffect(isPulseAnimating ? 1.02 : 1.0) // Pulse Animation
                                }
                                .disabled(isPurchasing)
                                .onAppear {
                                    withAnimation(Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                                        isPulseAnimating = true
                                    }
                                }
                                
                            } else {
                                // Loading State
                                ProgressView()
                                    .padding()
                            }
                            
                            // MARK: - Folder Links (Restore, Privacy, Terms)
                            HStack(spacing: 24) {
                                Button("Terms of Service") { activeSheet = .terms }
                                Button("Privacy Policy") { activeSheet = .privacy }
                                Button("Restore") {
                                    Task {
                                        await restore()
                                    }
                                }
                            }
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(DesignSystem.Colors.textSecondary.opacity(0.7))
                            .padding(.top, 4)
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, isIpad ? 10 : 20)
                    }
                    .frame(minHeight: geometry.size.height)
                }
            }
        }
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
        .alert("Subscription", isPresented: $showingAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func purchase(package: Package) async {
        isPurchasing = true
        do {
            try await subscriptionService.purchase(package: package)
            // Successful purchase will update isPro, ensuring RootView switches content automatically.
        } catch {
            if !error.localizedDescription.contains("cancelled") {
                alertMessage = error.localizedDescription
                showingAlert = true
            }
        }
        isPurchasing = false
    }
    
    private func restore() async {
        isPurchasing = true
        do {
            try await subscriptionService.restorePurchases()
            if subscriptionService.isPro {
                alertMessage = "Purchases restored successfully!"
            } else {
                alertMessage = "No active subscription found to restore."
            }
            showingAlert = true
        } catch {
            alertMessage = error.localizedDescription
            showingAlert = true
        }
        isPurchasing = false
    }
}

struct PremiumFeatureRow: View {
    let icon: String
    let text: String
    var isIpad: Bool = false
    
    var body: some View {
        HStack(spacing: isIpad ? 12 : 16) {
            Image(systemName: icon)
                .font(.system(size: isIpad ? 16 : 20))
                .foregroundColor(DesignSystem.Colors.royalBlue)
                .frame(width: isIpad ? 20 : 24)
            
            Text(text)
                .font(.system(size: isIpad ? 14 : 17, weight: .medium))
                .foregroundColor(DesignSystem.Colors.deepCharcoal)
            
            Spacer()
            
            Image(systemName: "checkmark")
                .font(.system(size: isIpad ? 12 : 14, weight: .bold))
                .foregroundColor(DesignSystem.Colors.royalBlue.opacity(0.6))
        }
        .padding(isIpad ? 12 : 16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 4)
    }
}

#Preview {
    PaywallView()
        .environmentObject(SubscriptionService.shared)
}
