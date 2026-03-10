//
//  AppStyle.swift
//  CJIS Daily
//
//  Created by Ramon Dominguez on 12/18/25.
//
import SwiftUI

enum AppStyle {

    // MARK: Layout
    static let contentMaxWidth: CGFloat = 560
    static let cardCorner: CGFloat = 18
    static let cjisBlue = Color(red: 0.11, green: 0.32, blue: 0.63)
    static let cjisBlueSoft = Color(red: 0.11, green: 0.32, blue: 0.63).opacity(0.12)

    // MARK: Typography (mock-like)
    static func titleSerif(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }

    static func body(_ size: CGFloat = 16, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .default)
    }

    // MARK: Colors
    static func ink(isDark: Bool) -> Color {
        isDark ? .white : .black
    }

    static func cardFill(isDark: Bool) -> Color {
        isDark ? Color.white.opacity(0.06) : Color.black.opacity(0.04)
    }

    static func cardStroke(isDark: Bool) -> Color {
        (isDark ? Color.white : Color.black).opacity(0.10)
    }

    static func primaryButtonFill(isDark: Bool) -> Color {
        isDark ? Color.white.opacity(0.90) : Color.black.opacity(0.85)
    }

    static func primaryButtonText(isDark: Bool) -> Color {
        isDark ? .black : .white
    }
}

struct AppCard<Content: View>: View {
    let isDark: Bool
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: AppStyle.cardCorner, style: .continuous)
                    .fill(AppStyle.cardFill(isDark: isDark))
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppStyle.cardCorner, style: .continuous)
                    .stroke(AppStyle.cardStroke(isDark: isDark), lineWidth: 1)
            )
    }
}
