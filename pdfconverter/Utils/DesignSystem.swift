import SwiftUI
import UIKit

struct DesignSystem {
    struct Colors {
        // Primitive Colors (Fixed)
        static let ghostWhite = Color(hex: "F8F9FA")
        static let deepCharcoal = Color(hex: "1C1C1E")
        static let royalBlue = Color(hex: "0055FF")
        static let metallicGold = Color(hex: "D4AF37")
        static let matteBlack = Color(hex: "111111")
        static let slateGrey = Color(hex: "666666")
        
        // Semantic Colors (Forced Light Mode)
        static var background: Color {
            return ghostWhite // Always Ghost White
        }
        
        static var secondaryBackground: Color {
            return .white // Always White
        }
        
        static var textPrimary: Color {
            return deepCharcoal // Always Dark Text
        }
        
        static var textSecondary: Color {
            return slateGrey // Always Grey Text
        }
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(DesignSystem.Colors.royalBlue)
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline)
            .foregroundColor(DesignSystem.Colors.textSecondary)
            .padding()
            .background(Color.clear)
    }
}
