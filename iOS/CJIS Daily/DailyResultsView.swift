//
//  DailyResultsView.swift
//  CJIS Daily
//
//  Created by Ramon Dominguez on 12/31/25.
//
import SwiftUI

struct DailyResultsView: View {
    let todayCorrect: Int
    let todayTotal: Int
    let lifetimeCorrect: Int
    let lifetimeTotal: Int

    let onDone: () -> Void

    @AppStorage("themeMode") private var themeModeRaw: String = ThemeMode.light.rawValue

    private var isDark: Bool { ThemeMode(rawValue: themeModeRaw) == .dark }
    private var inkColor: Color { AppStyle.ink(isDark: isDark) }
    private var brandBlue: Color { AppStyle.cjisBlue }

    private var todayPercentText: String {
        guard todayTotal > 0 else { return "—" }
        let pct = Int(((Double(todayCorrect) / Double(todayTotal)) * 100.0).rounded())
        return "\(pct)%"
    }

    private var lifetimePercentText: String {
        guard lifetimeTotal > 0 else { return "—" }
        let pct = Int((Double(lifetimeCorrect) / Double(lifetimeTotal)) * 100.0)
        return "\(pct)%"
    }

    var body: some View {
        ZStack {
            PaperBackground()

            VStack(spacing: 0) {
                Spacer(minLength: 24)

                VStack(alignment: .leading, spacing: 14) {
                    AppCard(isDark: isDark) {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Today’s Results")
                                .font(AppStyle.titleSerif(24, weight: .semibold))
                                .foregroundColor(brandBlue)

                            HStack(alignment: .firstTextBaseline) {
                                Text("\(todayCorrect) / \(todayTotal)")
                                    .font(AppStyle.titleSerif(28, weight: .bold))
                                    .foregroundColor(inkColor)

                                Spacer()

                                Text(todayPercentText)
                                    .font(AppStyle.body(16, weight: .semibold))
                                    .foregroundColor(inkColor.opacity(0.75))
                                    .accessibilityLabel("Today's accuracy: \(todayPercentText)")
                            }

                            Rectangle()
                                .fill(AppStyle.cjisBlueSoft)
                                .frame(height: 1)

                            Text("Great work today. More CJIS tips and a new check unlock tomorrow.")
                                .font(AppStyle.body(14))
                                .foregroundColor(inkColor.opacity(0.75))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    AppCard(isDark: isDark) {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Overall Score")
                                .font(AppStyle.body(16, weight: .semibold))
                                .foregroundColor(inkColor)

                            HStack {
                                Text(lifetimeTotal > 0 ? "\(lifetimeCorrect) / \(lifetimeTotal)" : "No quizzes yet")
                                    .font(AppStyle.body(14))
                                    .foregroundColor(inkColor.opacity(0.78))

                                Spacer()

                                Text(lifetimePercentText)
                                    .font(AppStyle.body(14, weight: .semibold))
                                    .foregroundColor(brandBlue)
                                    .accessibilityLabel("Lifetime accuracy: \(lifetimePercentText)")
                            }

                            Text("This is your lifetime accuracy across all completed daily checks.")
                                .font(AppStyle.body(13))
                                .foregroundColor(inkColor.opacity(0.65))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    Button { onDone() } label: {
                        Text("Done")
                            .font(AppStyle.body(16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(brandBlue)
                            )
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 6)

                    Spacer()
                }
                .frame(maxWidth: AppStyle.contentMaxWidth, alignment: .leading)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.horizontal, 20)
            }
        }
    }
}
