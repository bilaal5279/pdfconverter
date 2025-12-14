import SwiftUI
import StoreKit

struct OnboardingView: View {
    @State private var currentPage = 0
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @Environment(\.requestReview) var requestReview
    
    // Animation State for Mesh Gradient
    @State private var animateGradient = false
    
    // Unified Premium Color Scheme: Royal Blue
    let primaryColor = DesignSystem.Colors.royalBlue
    
    let slides = [
        OnboardingSlide(
            title: "Scan Documents",
            description: "Transform physical papers into crystal-clear digital copies instantly.",
            imageName: "doc.viewfinder",
            tagline: "Precision Scanning"
        ),
        OnboardingSlide(
            title: "Convert & Export",
            description: "Generate professional PDFs or JPGs and share them anywhere.",
            imageName: "doc.on.doc.fill",
            tagline: "Universal Formats"
        ),
        OnboardingSlide(
            title: "Text Intelligence",
            description: "Unlock the text within your images using advanced AI recognition.",
            imageName: "text.viewfinder",
            tagline: "OCR Technology"
        )
    ]
    
    // Derived count including paywall
    var totalPages: Int { slides.count + 1 }
    
    var body: some View {
        ZStack {
            // Dynamic Mesh Gradient Background
            GeometryReader { geometry in
                ZStack {
                    DesignSystem.Colors.ghostWhite.ignoresSafeArea()
                    
                    // Animated Blobs
                    Circle()
                        .fill(primaryColor.opacity(0.15))
                        .frame(width: 300, height: 300)
                        .blur(radius: 60)
                        .offset(x: animateGradient ? -100 : 100, y: animateGradient ? -100 : 100)
                        .scaleEffect(animateGradient ? 1.2 : 1.0)
                    
                    Circle()
                        .fill(DesignSystem.Colors.royalBlue.opacity(0.1))
                        .frame(width: 400, height: 400)
                        .blur(radius: 80)
                        .offset(x: animateGradient ? 150 : -50, y: animateGradient ? 200 : -100)
                        .scaleEffect(animateGradient ? 1.1 : 0.8)
                    
                    Circle()
                        .fill(DesignSystem.Colors.metallicGold.opacity(0.05))
                        .frame(width: 250, height: 250)
                        .blur(radius: 50)
                        .offset(x: animateGradient ? -50 : 150, y: animateGradient ? 300 : 0)
                }
                .ignoresSafeArea()
                .onAppear {
                    withAnimation(Animation.easeInOut(duration: 5.0).repeatForever(autoreverses: true)) {
                        animateGradient.toggle()
                    }
                }
            }
            
            VStack {
                // Top Bar
                Color.clear.frame(height: 44).padding()
                
                Spacer() // Pushes content down if needed, but TabView takes space
                
                // Content Area card
                TabView(selection: $currentPage) {
                    // Feature Slides
                    ForEach(0..<slides.count, id: \.self) { index in
                        LuxurySlideView(slide: slides[index], primaryColor: primaryColor)
                            .tag(index)
                    }
                    
                    // Paywall Slide (Index 3)
                    PaywallView()
                        .tag(slides.count)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                // If on paywall, let it take full height/space? 
                // Currently fixed frame(height: 520). PaywallView needs more space usually.
                .frame(maxHeight: currentPage == slides.count ? .infinity : 520)
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: currentPage)
                
                // Indicators & Footer (Hide on Paywall)
                if currentPage < slides.count {
                    VStack(spacing: 0) {
                        // Indicators
                        HStack(spacing: 8) {
                            ForEach(0..<totalPages, id: \.self) { index in
                                if index < slides.count { // Don't show dot for paywall potentially? Or keep it?
                                    // User flow: 3 slides -> Paywall.
                                    // If we keep dots, it looks like part of flow.
                                    Capsule()
                                        .fill(currentPage == index ? primaryColor : Color.gray.opacity(0.3))
                                        .frame(width: currentPage == index ? 24 : 8, height: 8)
                                        .animation(.spring(), value: currentPage)
                                }
                            }
                        }
                        .padding(.vertical, 20)
                        
                        Spacer()
                        
                        // Action Button
                        Button(action: {
                            triggerHaptic(style: .medium)
                            withAnimation {
                                currentPage += 1
                            }
                        }) {
                            Text("Continue")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(primaryColor)
                                .cornerRadius(16)
                                .shadow(color: primaryColor.opacity(0.3), radius: 15, x: 0, y: 8)
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 30)
                    }
                }
            }
        }
        .onChange(of: currentPage) { _, newValue in
             if newValue == 1 {
                 requestReview()
             }
             if newValue == slides.count {
                 hasSeenOnboarding = true
             }
        }
    }
    
    private func triggerHaptic(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
}

struct LuxurySlideView: View {
    let slide: OnboardingSlide
    let primaryColor: Color
    
    var body: some View {
        VStack(spacing: 30) {
            // Floating Card Icon
            ZStack {
                RoundedRectangle(cornerRadius: 30)
                    .fill(Color.white)
                    .frame(width: 180, height: 180)
                    .shadow(color: Color.black.opacity(0.08), radius: 25, x: 0, y: 15)
                
                Image(systemName: slide.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 70, height: 70)
                    .foregroundColor(primaryColor)
            }
            .padding(.bottom, 10)
            
            VStack(spacing: 12) {
                Text(slide.tagline.uppercased())
                    .font(.system(size: 13, weight: .semibold))
                    .tracking(2)
                    .foregroundColor(primaryColor.opacity(0.8))
                
                Text(slide.title)
                    .font(.system(size: 34, weight: .bold)) // Clean System Font
                    .foregroundColor(DesignSystem.Colors.deepCharcoal)
                
                Text(slide.description)
                    .font(.system(size: 17, weight: .regular))
                    .foregroundColor(DesignSystem.Colors.slateGrey)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .lineSpacing(4)
            }
        }
    }
}

struct OnboardingSlide {
    let title: String
    let description: String
    let imageName: String
    let tagline: String
}

#Preview {
    OnboardingView()
}
