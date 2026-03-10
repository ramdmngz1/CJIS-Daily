//
//  SettingsView.swift
//  CJIS Daily
//
//  Created by Ramon Dominguez on 11/30/25.
//
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @AppStorage("themeMode") private var themeModeRaw: String = ThemeMode.light.rawValue

    // Dismiss binding (your iPad-safe approach)
    @Binding var isPresented: Bool

    @State private var showSavedMessage = false

    // MARK: - Derived
    private var themeMode: ThemeMode { ThemeMode(rawValue: themeModeRaw) ?? .light }
    private var isDark: Bool { themeMode == .dark }

    private var inkColor: Color { AppStyle.ink(isDark: isDark) }
    private var brandBlue: Color { isDark ? AppStyle.cjisBlue.opacity(0.88) : AppStyle.cjisBlue }

    var body: some View {
        ZStack(alignment: .topLeading) {
            PaperBackground()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {

                    // Header (matches TodayTip)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Settings")
                            .font(AppStyle.titleSerif(28))
                            .foregroundColor(brandBlue)

                        Text("Customize your daily CJIS experience.")
                            .font(AppStyle.body(15))
                            .foregroundColor(inkColor.opacity(0.75))

                        Rectangle()
                            .fill(AppStyle.cjisBlueSoft)
                            .frame(height: 1)
                            .padding(.top, 6)
                    }

                    // MARK: Daily Tip Time
                    AppCard(isDark: isDark) {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Daily Tip Time")
                                .font(AppStyle.titleSerif(18, weight: .semibold))
                                .foregroundColor(brandBlue)

                            Text("Choose what time you’d like to receive your CJIS daily tip notification.")
                                .font(AppStyle.body(15))
                                .foregroundColor(inkColor.opacity(0.75))

                            DatePicker(
                                "Time",
                                selection: $viewModel.notificationTime,
                                displayedComponents: .hourAndMinute
                            )
                            .labelsHidden()
                            .datePickerStyle(.wheel)
                            .frame(height: 160)
                            .environment(\.colorScheme, isDark ? .dark : .light)
                            .id(isDark)
                            .accessibilityLabel("Select notification time")

                            Button {
                                viewModel.saveNotificationTime()
                                showSavedMessage = true
                            } label: {
                                Text("Save & Schedule")
                                    .font(AppStyle.body(15, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .fill(brandBlue)
                                    )
                            }
                            .buttonStyle(.plain)
                            .alert("Daily tip time updated", isPresented: $showSavedMessage) {
                                Button("OK", role: .cancel) { }
                            }
                        }
                    }

                    // MARK: Appearance
                    AppCard(isDark: isDark) {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Appearance")
                                .font(AppStyle.titleSerif(18, weight: .semibold))
                                .foregroundColor(brandBlue)

                            Text("Choose how CJIS Daily matches your device’s look.")
                                .font(AppStyle.body(15))
                                .foregroundColor(inkColor.opacity(0.75))

                            Picker("Theme", selection: $themeModeRaw) {
                                ForEach(ThemeMode.allCases) { mode in
                                    Text(mode.displayName).tag(mode.rawValue)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                    }

                
                    // MARK: About
                    AppCard(isDark: isDark) {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("About CJIS Daily")
                                .font(AppStyle.titleSerif(18, weight: .semibold))
                                .foregroundColor(brandBlue)

                            Text("""
CJIS Daily is a personal awareness tool to help you stay familiar with the FBI CJIS Security Policy using short daily tips.

It does not access or store Criminal Justice Information (CJI) and is not affiliated with the FBI or DOJ.
""")
                            .font(AppStyle.body(15))
                            .foregroundColor(inkColor.opacity(0.75))

                            Rectangle()
                                .fill(AppStyle.cjisBlueSoft)
                                .frame(height: 1)
                                .padding(.vertical, 2)

                            if let privacyURL = URL(string: "https://www.copanostudios.com/privacy-cjis-daily") {
                                Link(destination: privacyURL) {
                                    HStack(spacing: 6) {
                                        Text("Privacy Policy")
                                            .font(AppStyle.body(15, weight: .semibold))
                                        Image(systemName: "arrow.up.right")
                                            .font(.system(size: 12, weight: .semibold))
                                    }
                                    .foregroundColor(brandBlue)
                                }
                                .accessibilityLabel("Privacy Policy")
                                .accessibilityHint("Opens privacy policy in browser")
                            }
                        }
                    }

                    Spacer(minLength: 24)
                }
                // iPad-friendly centered column
                .frame(maxWidth: AppStyle.contentMaxWidth, alignment: .leading)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.horizontal, 20)
                .padding(.top, 60)
                .padding(.bottom, 30)
            }

            // Close button (no haptic)
            Button {
                isPresented = false
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(brandBlue)
                    .padding(10)
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close settings")
            .padding(.top, 18)
            .padding(.leading, 14)
        }
        .environment(\.colorScheme, isDark ? .dark : .light)
    }
}

#Preview {
    SettingsView(isPresented: .constant(true))
        .environmentObject(AppViewModel())
}
