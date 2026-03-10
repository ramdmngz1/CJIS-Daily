//
//  RootView.swift
//  CJIS Daily
//
//  Created by Ramon Dominguez on 11/30/25.
//
import SwiftUI

struct RootView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @AppStorage("themeMode") private var themeModeRaw: String = ThemeMode.light.rawValue

    @State private var showingSettings = false

    private var themeMode: ThemeMode { ThemeMode(rawValue: themeModeRaw) ?? .light }
    private var preferredScheme: ColorScheme { themeMode == .dark ? .dark : .light }

    var body: some View {
        DailyPackView(showingSettings: $showingSettings)
            .environmentObject(viewModel)
            .preferredColorScheme(preferredScheme)
            .sheet(isPresented: $showingSettings) {
                SettingsView(isPresented: $showingSettings)
                    .environmentObject(viewModel)
                    .preferredColorScheme(preferredScheme)
            }
    }
}
