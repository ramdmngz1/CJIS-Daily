//
//  QuizProgressManager.swift
//  CJIS Daily
//
//  Tracks daily completion streak and lifetime quiz performance.
//

import Foundation

final class QuizProgressManager {

    static let shared = QuizProgressManager()

    struct State: Codable {
        var lastCompletionDate: Date?
        var streakCount: Int

        // Lifetime scoring
        var lifetimeCorrect: Int
        var lifetimeAnswered: Int

        // Prevent double-counting lifetime totals in the same day
        var lastScoreRecordedDayKey: String?
    }

    private let storageKey = "QuizProgressState_v2"
    private var state: State

    private init() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode(State.self, from: data),
           decoded.streakCount >= 0,
           decoded.lifetimeCorrect >= 0,
           decoded.lifetimeAnswered >= 0,
           decoded.lifetimeCorrect <= decoded.lifetimeAnswered {
            state = decoded
        } else {
            state = State(
                lastCompletionDate: nil,
                streakCount: 0,
                lifetimeCorrect: 0,
                lifetimeAnswered: 0,
                lastScoreRecordedDayKey: nil
            )
            persist()
        }
    }

    // MARK: - Public read access

    var currentStreak: Int { state.streakCount }
    var lifetimeCorrect: Int { state.lifetimeCorrect }
    var lifetimeAnswered: Int { state.lifetimeAnswered }

    var lifetimeAccuracy: Double {
        guard state.lifetimeAnswered > 0 else { return 0 }
        return Double(state.lifetimeCorrect) / Double(state.lifetimeAnswered)
    }

    /// Call when the user finishes the DAILY check for the day.
    /// Batches all state mutations into a single persist() call to avoid partial writes on crash.
    func recordDailyCheckIfNeeded(correct: Int, total: Int, date: Date = Date()) {
        let cal = Calendar.current
        let today = cal.startOfDay(for: date)
        let dayKey = Self.dayKey(for: date)

        // Streak: increment once per day
        if let last = state.lastCompletionDate, cal.isDate(last, inSameDayAs: today) {
            // Already recorded today — skip streak update
        } else {
            if let last = state.lastCompletionDate {
                let diff = cal.dateComponents([.day], from: cal.startOfDay(for: last), to: today).day ?? 0
                state.streakCount = diff == 1 ? state.streakCount + 1 : 1
            } else {
                state.streakCount = 1
            }
            state.lastCompletionDate = today
        }

        // Lifetime score: record once per day
        if state.lastScoreRecordedDayKey != dayKey {
            let clampedTotal = max(0, total)
            let clampedCorrect = max(0, min(correct, clampedTotal))
            state.lifetimeCorrect += clampedCorrect
            state.lifetimeAnswered += clampedTotal
            state.lastScoreRecordedDayKey = dayKey
        }

        persist()
    }

    // MARK: - ✅ Backwards-compatible API (so existing files compile)

    /// Legacy: used by older per-tip quizzes to only count the streak once/day.
    /// Keeps old code compiling while your new DailyCheckView becomes the real completion path.
    func markQuizCompletedIfNeeded(date: Date = Date()) {
        markDailyCompletedIfNeeded(date: date)
        // NOTE: Intentionally does NOT record lifetime score here.
        // Lifetime scoring should come from the Daily Check completion.
    }

    // MARK: - Internal: streak

    private func markDailyCompletedIfNeeded(date: Date) {
        let cal = Calendar.current
        let today = cal.startOfDay(for: date)

        // Don’t increment streak more than once per day
        if let last = state.lastCompletionDate, cal.isDate(last, inSameDayAs: today) {
            return
        }

        if let last = state.lastCompletionDate {
            let startLast = cal.startOfDay(for: last)
            let diff = cal.dateComponents([.day], from: startLast, to: today).day ?? 0

            if diff == 1 {
                state.streakCount += 1
            } else {
                state.streakCount = 1
            }
        } else {
            state.streakCount = 1
        }

        state.lastCompletionDate = today
        persist()
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(state) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private static let dayKeyFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = .current
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    static func dayKey(for date: Date) -> String {
        dayKeyFormatter.string(from: date)
    }

    #if DEBUG
    func debugResetAll() {
        state = State(
            lastCompletionDate: nil,
            streakCount: 0,
            lifetimeCorrect: 0,
            lifetimeAnswered: 0,
            lastScoreRecordedDayKey: nil
        )
        UserDefaults.standard.removeObject(forKey: storageKey)
    }
    #endif
}
