//
//  PaperBackground.swift
//  CJIS Daily
//
//  Created by Ramon Dominguez on 12/1/25.
//
import SwiftUI

struct PaperBackground: View {
    @AppStorage("themeMode") private var themeModeRaw: String = ThemeMode.light.rawValue

    private var isDark: Bool {
        ThemeMode(rawValue: themeModeRaw) == .dark
    }

    private var baseColor: Color {
        isDark
        ? Color(red: 0.08, green: 0.08, blue: 0.10)
        : Color(red: 0.97, green: 0.96, blue: 0.92)
    }

    var body: some View {
        baseColor
            .ignoresSafeArea()
            .overlay(
                LinearGradient(
                    colors: [
                        Color.black.opacity(isDark ? 0.35 : 0.12),
                        .clear,
                        Color.black.opacity(isDark ? 0.25 : 0.08)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .blendMode(.multiply)
                .opacity(0.4)
            )
            .overlay(
                Rectangle()
                    .stroke(Color.black.opacity(isDark ? 0.25 : 0.06), lineWidth: 0.5)
                    .blur(radius: 0.5)
                    .opacity(0.7)
            )
    }
}
