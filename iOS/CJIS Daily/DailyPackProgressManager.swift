//
//  DailyPackProgressManager.swift
//  CJIS Daily
//
//  Tracks whether today's Daily Check is completed and stores today's score.
//
import Foundation

final class DailyPackProgressManager {

    static let shared = DailyPackProgressManager()

    struct Score: Codable {
        var correct: Int
        var total: Int
    }

    struct State: Codable {
        var dayKey: String
        var dailyCheckCompleted: Bool
        var score: Score?
    }

    private let storageKey = "DailyPackProgressState_v1"
    private var state: State

    private init() {
        let todayKey = Self.dayKey(for: Date())

        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode(State.self, from: data),
           decoded.dayKey == todayKey {
            state = decoded
        } else {
            state = State(dayKey: todayKey, dailyCheckCompleted: false, score: nil)
            persist()
        }
    }

    func resetIfNewDay(date: Date = Date()) {
        let todayKey = Self.dayKey(for: date)
        guard state.dayKey != todayKey else { return }
        state = State(dayKey: todayKey, dailyCheckCompleted: false, score: nil)
        persist()
    }

    func markDailyCheckCompleted(correct: Int, total: Int) {
        resetIfNewDay()
        state.dailyCheckCompleted = true
        let clampedTotal = max(0, total)
        state.score = Score(correct: max(0, min(correct, clampedTotal)), total: clampedTotal)
        persist()
    }

    /// Reads roll the day forward first so a stale singleton (app suspended across midnight)
    /// doesn't return yesterday's "completed" state for today.
    var isDailyCheckCompleted: Bool {
        resetIfNewDay()
        return state.dailyCheckCompleted
    }

    var todaysScore: Score? {
        resetIfNewDay()
        return state.score
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
}
