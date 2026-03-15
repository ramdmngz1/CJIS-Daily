//
//  DailyPackView.swift
//  CJIS Daily
//
//  5 tips per day with back/next navigation.
//  Typography refinement: ensure all titles use consistent serif styling.
//

import SwiftUI

struct DailyPackView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @AppStorage("themeMode") private var themeModeRaw: String = ThemeMode.light.rawValue
    @Binding var showingSettings: Bool

    private enum ActiveSheet: Identifiable {
        case dailyCheck, results
        var id: Self { self }
    }

    @State private var index: Int = 0
    @State private var showDetails: Bool = false
    @State private var activeSheet: ActiveSheet? = nil
    @State private var todaysScore: DailyPackProgressManager.Score? = nil

    @State private var screenOpacity: Double = 0
    @State private var detailsOpacity: Double = 0

    private var isDark: Bool { ThemeMode(rawValue: themeModeRaw) == .dark }
    private var inkColor: Color { AppStyle.ink(isDark: isDark) }
    private var brandBlue: Color { AppStyle.cjisBlue }

    private var tips: [CJISTip] { viewModel.todayTips }
    private var currentTip: CJISTip? {
        guard index >= 0, index < tips.count else { return nil }
        return tips[index]
    }

    private var dailyCompleted: Bool { DailyPackProgressManager.shared.isDailyCheckCompleted }

    private func refreshForCurrentDay() {
        DailyPackProgressManager.shared.resetIfNewDay()
        viewModel.refreshTodayTips()
        if index >= tips.count { index = 0 }
        todaysScore = DailyPackProgressManager.shared.todaysScore
        screenOpacity = 0
        withAnimation(.easeInOut(duration: 0.5).delay(0.05)) {
            screenOpacity = 1
        }
    }

    var body: some View {
        ZStack {
            PaperBackground()

            VStack(spacing: 0) {
                header

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 14) {
                        if let tip = currentTip {
                            tipCard(tip)
                        } else {
                            emptyState
                        }

                        Spacer(minLength: 36)
                    }
                    .frame(maxWidth: AppStyle.contentMaxWidth, alignment: .leading)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.horizontal, 20)
                    .padding(.top, 14)
                }
            }
            .opacity(screenOpacity)
        }
        .onAppear {
            refreshForCurrentDay()
        }
        // Re-check the day every time the app returns from background.
        // onAppear does not fire on foreground resume, so this handles the
        // "same tips all week" bug when the user taps a daily notification.
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            refreshForCurrentDay()
        }
        .onChange(of: index) { _ in
            showDetails = false
            detailsOpacity = 0
        }
        .fullScreenCover(item: $activeSheet) { sheet in
            switch sheet {
            case .dailyCheck:
                DailyCheckView(tips: tips) { correct, total in
                    DailyPackProgressManager.shared.markDailyCheckCompleted(correct: correct, total: total)
                    QuizProgressManager.shared.recordDailyCheckIfNeeded(correct: correct, total: total)
                    todaysScore = DailyPackProgressManager.Score(correct: correct, total: total)
                    activeSheet = .results
                }
            case .results:
                let score = todaysScore ?? DailyPackProgressManager.shared.todaysScore
                DailyResultsView(
                    todayCorrect: score?.correct ?? 0,
                    todayTotal: score?.total ?? 0,
                    lifetimeCorrect: QuizProgressManager.shared.lifetimeCorrect,
                    lifetimeTotal: QuizProgressManager.shared.lifetimeAnswered
                ) {
                    activeSheet = nil
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            navBar
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, 8)
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("CJIS Daily")
                    .font(AppStyle.titleSerif(26))
                    .foregroundColor(brandBlue)

                Text("Tip \(index + 1) of \(max(tips.count, 1))")
                    .font(AppStyle.body(13, weight: .semibold))
                    .foregroundColor(inkColor.opacity(0.6))
            }

            Spacer()

            Button { showingSettings = true } label: {
                Image(systemName: "gearshape.fill")
                    .foregroundColor(brandBlue)
                    .padding(10)
                    .frame(minWidth: 44, minHeight: 44)
                    .background(Circle().fill(AppStyle.cardFill(isDark: isDark)))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Settings")
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 6)
    }

    // MARK: - Tip Card

    private func tipCard(_ tip: CJISTip) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            AppCard(isDark: isDark) {
                VStack(alignment: .leading, spacing: 10) {
                    Text(tip.title)
                        .font(AppStyle.titleSerif(20, weight: .semibold))
                        .foregroundColor(inkColor)

                    Text(tip.shortText)
                        .font(AppStyle.body(16))
                        .foregroundColor(inkColor.opacity(0.78))

                    Rectangle()
                        .fill(AppStyle.cjisBlueSoft)
                        .frame(height: 1)
                        .padding(.top, 6)

                    Button { toggleDetails() } label: {
                        HStack(spacing: 6) {
                            Text("More detail")
                                .font(AppStyle.body(15, weight: .semibold))
                            Image(systemName: showDetails ? "chevron.up" : "chevron.down")
                                .font(.system(size: 13, weight: .bold))
                        }
                        .foregroundColor(brandBlue)
                        .padding(.vertical, 6)
                    }
                    .buttonStyle(.plain)

                    if showDetails {
                        VStack(alignment: .leading, spacing: 10) {
                            Text(tip.longText)
                                .font(AppStyle.body(15))
                                .foregroundColor(inkColor.opacity(0.8))
                                .opacity(detailsOpacity)

                            Text(tip.section)
                                .font(AppStyle.body(13, weight: .semibold))
                                .foregroundColor(brandBlue.opacity(0.9))
                                .opacity(detailsOpacity)
                        }
                        .transition(.move(edge: .top))
                    }
                }
            }

            if dailyCompleted {
                AppCard(isDark: isDark) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Completed for today")
                            .font(AppStyle.titleSerif(18, weight: .semibold))
                            .foregroundColor(inkColor)

                        Text("You can review these tips any time. More tips and a new check unlock tomorrow.")
                            .font(AppStyle.body(14))
                            .foregroundColor(inkColor.opacity(0.72))
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private func toggleDetails() {
        if showDetails {
            withAnimation(.easeOut(duration: 0.12)) { detailsOpacity = 0 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                withAnimation(.easeInOut(duration: 0.22)) {
                    showDetails = false
                }
            }
        } else {
            detailsOpacity = 0
            withAnimation(.easeInOut(duration: 0.22)) {
                showDetails = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
                withAnimation(.easeIn(duration: 0.18)) {
                    detailsOpacity = 1
                }
            }
        }
    }

    private var emptyState: some View {
        AppCard(isDark: isDark) {
            Text("Loading tips…")
                .font(AppStyle.body(16, weight: .semibold))
                .foregroundColor(inkColor)
        }
    }

    private var navBar: some View {
        HStack(spacing: 12) {
            if index > 0 {
                Button { index -= 1 } label: {
                    Text("Back")
                        .font(AppStyle.body(15, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(RoundedRectangle(cornerRadius: 14).fill(brandBlue.opacity(0.85)))
                }
                .buttonStyle(.plain)
            }

            Button {
                if index < tips.count - 1 {
                    index += 1
                } else if dailyCompleted {
                    activeSheet = .results
                } else {
                    activeSheet = .dailyCheck
                }
            } label: {
                Text(index < tips.count - 1 ? "Next" : dailyCompleted ? "View Results" : "Start Daily Check")
                    .font(AppStyle.body(15, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(RoundedRectangle(cornerRadius: 14).fill(brandBlue))
            }
            .buttonStyle(.plain)
            .disabled(tips.isEmpty)
        }
    }
}
