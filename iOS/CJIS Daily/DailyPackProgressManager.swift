//
//  DailyPackProgressManager.swift
//  CJIS Daily
//
//  Tracks which of today's 5 tips have been viewed (Next counts as viewed) and whether today's Daily Check is completed.
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
        var viewedTipIds: Set<Int>
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
            state = State(dayKey: todayKey, viewedTipIds: [], dailyCheckCompleted: false, score: nil)
            persist()
        }
    }

    func resetIfNewDay(date: Date = Date()) {
        let todayKey = Self.dayKey(for: date)
        guard state.dayKey != todayKey else { return }
        state = State(dayKey: todayKey, viewedTipIds: [], dailyCheckCompleted: false, score: nil)
        persist()
    }

    func markViewed(tipId: Int) {
        resetIfNewDay()
        state.viewedTipIds.insert(tipId)
        persist()
    }

    func markDailyCheckCompleted(correct: Int, total: Int) {
        resetIfNewDay()
        state.dailyCheckCompleted = true
        state.score = Score(correct: correct, total: total)
        persist()
    }

    var isDailyCheckCompleted: Bool {
        state.dailyCheckCompleted
    }

    var todaysScore: Score? {
        state.score
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
