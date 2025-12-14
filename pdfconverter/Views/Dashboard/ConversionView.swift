import SwiftUI
import UniformTypeIdentifiers

struct ConversionView: View {
    let fileURL: URL
    var onConversionComplete: ([String]) -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var conversionState: ConversionState = .idle
    @State private var scanOffset: CGFloat = -100
    @State private var rotation: Double = 0
    @State private var showSuccess = false
    @State private var particleScale: CGFloat = 0.5
    @State private var particleOpacity: Double = 0
    
    enum ConversionState {
        case idle
        case converting
        case success
        case failed
    }
    
    var body: some View {
        ZStack {
            // MARK: - Premium Background
            DesignSystem.Colors.background.ignoresSafeArea()
            
            // Ambient Gradients (Light Mode Optimized)
            ZStack {
                Circle()
                    .fill(DesignSystem.Colors.royalBlue.opacity(0.1)) // Subtle Blue
                    .frame(width: 350, height: 350)
                    .blur(radius: 80)
                    .offset(x: -120, y: -300)
                
                Circle()
                    .fill(DesignSystem.Colors.metallicGold.opacity(0.15)) // Enhanced Gold
                    .frame(width: 300, height: 300)
                    .blur(radius: 70)
                    .offset(x: 120, y: 200)
            }
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header (Close Button)
                if conversionState != .success {
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(DesignSystem.Colors.textSecondary) // Dark Icon
                                .padding(12)
                                .background(Material.thinMaterial) // Glassy button
                                .clipShape(Circle())
                                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                } else {
                    Spacer().frame(height: 70)
                }
                
                Spacer()
                
                // MARK: - Center Visualization
                ZStack {
                    // 1. Rotating Rings (Converting State)
                    if conversionState == .converting {
                        Group {
                            Circle()
                                .stroke(
                                    LinearGradient(colors: [DesignSystem.Colors.royalBlue, .clear], startPoint: .top, endPoint: .bottom),
                                    lineWidth: 3
                                )
                                .frame(width: 240, height: 240)
                                .rotationEffect(.degrees(rotation))
                            
                            Circle()
                                .stroke(
                                    LinearGradient(colors: [DesignSystem.Colors.metallicGold, .clear], startPoint: .bottom, endPoint: .top),
                                    lineWidth: 3
                                )
                                .frame(width: 200, height: 200)
                                .rotationEffect(.degrees(-rotation * 1.5))
                        }
                        .transition(.opacity)
                    }
                    
                    // 2. Success Particles (Success State)
                    if conversionState == .success {
                        ForEach(0..<8) { i in
                            Circle()
                                .fill(DesignSystem.Colors.royalBlue)
                                .frame(width: 8, height: 8)
                                .offset(y: -120)
                                .rotationEffect(.degrees(Double(i) * 45))
                                .scaleEffect(particleScale)
                                .opacity(particleOpacity)
                        }
                    }
                    
                    // 3. Main Icon Container
                    ZStack {
                        // Glass Background (Light Mode)
                        RoundedRectangle(cornerRadius: 36)
                            .fill(Color.white.opacity(0.7)) // More opacity for white
                            .background(Material.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 36))
                            .shadow(color: Color.black.opacity(0.08), radius: 25, x: 0, y: 10) // Soft shadow
                            .overlay(
                                RoundedRectangle(cornerRadius: 36)
                                    .stroke(LinearGradient(colors: [.white, .white.opacity(0.0)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1.5)
                            )
                            .frame(width: 160, height: 200)
                        
                        // Icon / Content
                        if conversionState == .success {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 72))
                                .foregroundStyle(LinearGradient(colors: [DesignSystem.Colors.royalBlue, DesignSystem.Colors.royalBlue.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .shadow(color: DesignSystem.Colors.royalBlue.opacity(0.3), radius: 10, x: 0, y: 5)
                                .transition(.scale.combined(with: .opacity))
                        } else {
                            Image(systemName: "doc.fill")
                                .font(.system(size: 64))
                                .foregroundColor(DesignSystem.Colors.royalBlue.opacity(0.8)) // Darker blue icon
                                .shadow(color: DesignSystem.Colors.royalBlue.opacity(0.2), radius: 10, x: 0, y: 5)
                        }
                        
                        // Scanner Beam (Converting State)
                        if conversionState == .converting {
                            Rectangle()
                                .fill(
                                    LinearGradient(colors: [.clear, DesignSystem.Colors.royalBlue, .clear], startPoint: .leading, endPoint: .trailing)
                                )
                                .frame(width: 160, height: 3)
                                .shadow(color: DesignSystem.Colors.royalBlue.opacity(0.5), radius: 8, x: 0, y: 0)
                                .offset(y: scanOffset)
                                .mask(RoundedRectangle(cornerRadius: 36).frame(width: 160, height: 200))
                        }
                    }
                }
                .padding(.bottom, 50)
                
                // MARK: - Status Text
                VStack(spacing: 16) {
                    Text(titleText)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(DesignSystem.Colors.textPrimary) // Dark Text
                        .multilineTextAlignment(.center)
                    
                    Text(subtitleText)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(DesignSystem.Colors.textSecondary) // Grey Text
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .lineSpacing(4)
                }
                
                Spacer()
                
                // MARK: - Action Button
                if conversionState == .idle {
                    Button(action: startConversion) {
                        Text("Convert to PDF")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                            .background(
                                LinearGradient(colors: [DesignSystem.Colors.royalBlue, Color.blue], startPoint: .leading, endPoint: .trailing)
                            )
                            .cornerRadius(20)
                            .shadow(color: DesignSystem.Colors.royalBlue.opacity(0.4), radius: 15, x: 0, y: 8)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                } else if conversionState == .success {
                    Button(action: {
                        dismiss()
                        onConversionComplete(savedPathsResult)
                    }) {
                        Text("Open Document")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white) // White text on black button
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                            .background(DesignSystem.Colors.textPrimary) // Black/Charcoal button for contrast
                            .cornerRadius(20)
                            .shadow(color: Color.black.opacity(0.2), radius: 15, x: 0, y: 8)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                } else {
                     Spacer().frame(height: 100)
                }
            }
        }
        .onAppear {
            // Auto-start animations handled in startConversion
        }
    }
    
    // MARK: - State properties
    // Temporary storage for results to pass after animation
    @State private var savedPathsResult: [String] = []
    
    // MARK: - Computeds
    private var titleText: String {
        switch conversionState {
        case .idle: return "Ready to Transform"
        case .converting: return "Processing..."
        case .success: return "Conversion Complete"
        case .failed: return "Optimization Failed"
        }
    }
    
    private var subtitleText: String {
        switch conversionState {
        case .idle: return "Convert \"\(fileURL.lastPathComponent)\" into a high-quality PDF document."
        case .converting: return "Scanning document structure and optimizing assets."
        case .success: return "Your document has been professionally processed and is ready for use."
        case .failed: return "We encountered an issue processing your file. Please try again."
        }
    }
    
    // MARK: - Logic
    private func startConversion() {
        withAnimation(.easeInOut(duration: 0.5)) {
            conversionState = .converting
        }
        
        // Start Animations
        withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
            rotation = 360
        }
        
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            scanOffset = 100
        }
        
        Task {
            // Premium Delay
            try? await Task.sleep(nanoseconds: 2_000_000_000) // 2s
            
            var savedPaths: [String] = []
            
            guard fileURL.startAccessingSecurityScopedResource() else {
                await MainActor.run { conversionState = .failed }
                return
            }
            defer { fileURL.stopAccessingSecurityScopedResource() }
            
            let ext = fileURL.pathExtension.lowercased()
            
            // Conversion Logic (Same as before)
            if ext == "pdf" {
                if let images = PDFService.shared.convertPDFToImages(url: fileURL) {
                    for image in images {
                        if let path = FileService.shared.saveImage(image) {
                            savedPaths.append(path)
                        }
                    }
                }
            } else if ["docx", "txt", "rtf", "doc"].contains(ext) {
                if let images = await PDFService.shared.convertDocumentToImages(url: fileURL) {
                    for image in images {
                        if let path = FileService.shared.saveImage(image) {
                            savedPaths.append(path)
                        }
                    }
                }
            } else {
                do {
                    let data = try Data(contentsOf: fileURL)
                    if let image = UIImage(data: data) {
                        if let path = FileService.shared.saveImage(image) {
                            savedPaths.append(path)
                        }
                    }
                } catch {
                    print("Error: \(error)")
                }
            }
            
            await MainActor.run {
                if !savedPaths.isEmpty {
                    savedPathsResult = savedPaths
                    
                    // Success Animation Trigger
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                        conversionState = .success
                    }
                    // Particle Burst
                    withAnimation(.easeOut(duration: 0.8)) {
                        particleScale = 1.0
                        particleOpacity = 1.0
                    }
                    withAnimation(.easeIn(duration: 0.5).delay(0.5)) {
                        particleOpacity = 0.0 // Fade out particles
                    }
                    
                } else {
                    withAnimation { conversionState = .failed }
                }
            }
        }
    }
}
