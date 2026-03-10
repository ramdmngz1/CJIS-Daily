//
//  CJIS_DailyApp.swift
//  CJIS Daily
//
//  Created by Ramon Dominguez on 11/30/25.
//
import SwiftUI

@main
struct CJISDailyApp: App {
    @StateObject private var viewModel = AppViewModel()
    @AppStorage("themeMode") private var themeModeRaw = ThemeMode.light.rawValue

    init() {
        NotificationManager.shared.requestAuthorization()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(viewModel)
                .preferredColorScheme(
                    (ThemeMode(rawValue: themeModeRaw) ?? .light) == .dark ? .dark : .light
                )
        }
    }
}
