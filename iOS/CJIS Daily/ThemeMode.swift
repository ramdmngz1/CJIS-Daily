//
//  ThemeMode.swift
//  CJIS Daily
//
//  Created by Ramon Dominguez on 11/30/25.
//
import Foundation

enum ThemeMode: String, CaseIterable, Identifiable {
    case light
    case dark

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }
}
