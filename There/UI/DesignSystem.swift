import SwiftUI

/// 2026 原生 macOS 风格设计系统规范与 Design Tokens
/// 遵循 macOS Sequoia / HIG 标准：通透材质、动态重点色、精细微边框与 SF 排版
enum TimefolkTheme {
    // MARK: - 圆角规范 (Continuous Squircles)
    enum Radius {
        static let small: CGFloat = 6
        static let medium: CGFloat = 8
        static let large: CGFloat = 10
        static let card: CGFloat = 12
        static let pill: CGFloat = 999
    }
    
    // MARK: - 语义化颜色与透明度
    enum Colors {
        // 卡片与控件微背景
        static func cardBackground(colorScheme: ColorScheme) -> Color {
            colorScheme == .dark
                ? Color.white.opacity(0.06)
                : Color.black.opacity(0.04)
        }
        
        static func cardHoverBackground(colorScheme: ColorScheme) -> Color {
            colorScheme == .dark
                ? Color.white.opacity(0.10)
                : Color.black.opacity(0.07)
        }
        
        static func cardActiveBackground(colorScheme: ColorScheme) -> Color {
            colorScheme == .dark
                ? Color.white.opacity(0.14)
                : Color.black.opacity(0.11)
        }
        
        // 超细微 0.5pt 边框 (macOS 原生精细度)
        static func hairlineBorder(colorScheme: ColorScheme) -> Color {
            colorScheme == .dark
                ? Color.white.opacity(0.12)
                : Color.black.opacity(0.08)
        }
        
        static func cardHighlight(colorScheme: ColorScheme) -> Color {
            colorScheme == .dark
                ? Color.white.opacity(0.18)
                : Color.white.opacity(0.60)
        }
        
        // 深浅模式高对比度强调色（用于文字与图标，避免深色模式下发暗模糊）
        static func contrastAccent(colorScheme: ColorScheme) -> Color {
            colorScheme == .dark
                ? Color(red: 0.42, green: 0.74, blue: 1.0)
                : Color.accentColor
        }

        // 阴影
        static func subtleShadow(colorScheme: ColorScheme) -> Color {
            colorScheme == .dark
                ? Color.black.opacity(0.4)
                : Color.black.opacity(0.08)
        }
    }
    
    // MARK: - 弹性动效
    enum Animation {
        static let smooth = SwiftUI.Animation.spring(response: 0.24, dampingFraction: 0.82)
        static let quick = SwiftUI.Animation.spring(response: 0.18, dampingFraction: 0.86)
        static let bounce = SwiftUI.Animation.spring(response: 0.30, dampingFraction: 0.70)
    }
}

// MARK: - 便捷 View Modifiers

extension View {
    /// 原生 macOS 磨砂卡片样式
    func macCardStyle(
        cornerRadius: CGFloat = TimefolkTheme.Radius.large,
        padding: CGFloat = 10
    ) -> some View {
        self
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.regularMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .strokeBorder(Color.primary.opacity(0.06), lineWidth: 0.5)
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
    
    /// 原生 macOS 精致内高光边框
    func macHairlineStroke(
        cornerRadius: CGFloat = TimefolkTheme.Radius.medium,
        lineWidth: CGFloat = 0.5
    ) -> some View {
        self.overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.08), lineWidth: lineWidth)
        )
    }
}
