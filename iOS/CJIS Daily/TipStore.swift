//
//  TipStore.swift
//  CJIS Daily
//
//  Created by Ramon Dominguez on 11/30/25.
//
import Foundation

final class TipStore {
    static let shared = TipStore()
    let tips: [CJISTip]

    private init() {
        if let url = Bundle.main.url(forResource: "cjis_tips", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let decoded = try? JSONDecoder().decode([CJISTip].self, from: data) {
            tips = decoded
        } else {
            tips = []
            print("⚠️ Failed to load cjis_tips.json")
        }
    }

    /// Legacy: one deterministic tip per calendar day (kept for backwards compatibility).
    func tipForToday(date: Date = Date()) -> CJISTip? {
        guard !tips.isEmpty else { return nil }
        let cal = Calendar.current
        let dayOfYear = cal.ordinality(of: .day, in: .year, for: date) ?? 1
        let index = (dayOfYear - 1) % tips.count
        return tips[index]
    }

    /// Returns a deterministic pack of `count` tips for the given day.
    /// - Parameters:
    ///   - count: How many tips to include in the pack (e.g., 5).
    ///   - date: Day to compute the pack for.
    ///   - requireQuizQuestions: When true, only tips that have at least 1 quiz question are eligible.
    func tipsForToday(count: Int = 5, date: Date = Date(), requireQuizQuestions: Bool = true) -> [CJISTip] {
        guard count > 0 else { return [] }

        // Pick from either all tips, or only those that have quiz questions.
        let eligible: [CJISTip]
        if requireQuizQuestions {
            eligible = tips.filter { !DailyQuizStore.shared.questions(for: $0.id).isEmpty }
        } else {
            eligible = tips
        }

        guard !eligible.isEmpty else { return [] }

        let cal = Calendar.current
        let dayOfYear = cal.ordinality(of: .day, in: .year, for: date) ?? 1

        // Deterministic rotation with wraparound (no randomness during App Review).
        let startIndex = ((dayOfYear - 1) * count) % eligible.count

        let target = min(count, eligible.count)
        var results: [CJISTip] = []
        var seenIds = Set<Int>()
        results.reserveCapacity(target)

        for i in 0..<eligible.count {
            guard results.count < target else { break }
            let candidate = eligible[(startIndex + i) % eligible.count]
            if seenIds.insert(candidate.id).inserted {
                results.append(candidate)
            }
        }

        return results
    }
}
