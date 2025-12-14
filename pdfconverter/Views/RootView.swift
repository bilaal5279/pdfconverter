import SwiftUI

struct RootView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @EnvironmentObject var subscriptionService: SubscriptionService
    
    var body: some View {
        Group {
            if !hasSeenOnboarding {
                OnboardingView()
            } else if subscriptionService.isPro {
                DashboardView()
            } else {
                PaywallView()
            }
        }
        .animation(.default, value: subscriptionService.isPro)
        .animation(.default, value: hasSeenOnboarding)
    }
}

#Preview {
    RootView()
}
