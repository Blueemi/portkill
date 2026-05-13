import SwiftUI

enum PortTypography {
    static func sfPro(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .default)
    }
}
