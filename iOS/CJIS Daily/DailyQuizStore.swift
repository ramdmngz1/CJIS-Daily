//
//  DailyQuizStore.swift
//  CJIS Daily
//
//  Created by Ramon Dominguez on 12/9/25.
//
//
//  DailyQuizStore.swift
//  CJIS Daily
//
import Foundation

struct TipQuizSet: Codable {
    let tipId: Int
    let questions: [QuizQuestion]
}

final class DailyQuizStore {

    static let shared = DailyQuizStore()

    private var questionsByTipId: [Int: [QuizQuestion]] = [:]

    private init() {
        loadFromBundle()
    }

    private func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        // Configure if needed (dates, etc.) – not needed here.
        return decoder
    }

    private func loadFromBundle() {
        guard let url = Bundle.main.url(forResource: "cjis_quizzes", withExtension: "json") else {
            print("DailyQuizStore: cjis_quizzes.json not found in bundle.")
            questionsByTipId = [:]
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let decoder = makeDecoder()
            let sets = try decoder.decode([TipQuizSet].self, from: data)

            var map: [Int: [QuizQuestion]] = [:]
            for set in sets {
                map[set.tipId] = set.questions
            }
            questionsByTipId = map
            print("DailyQuizStore: Loaded quizzes for \(questionsByTipId.keys.count) tip IDs.")
        } catch {
            print("DailyQuizStore: Failed to load or decode cjis_quizzes.json: \(error)")
            questionsByTipId = [:]
        }
    }

    func questions(for tipId: Int) -> [QuizQuestion] {
        questionsByTipId[tipId] ?? []
    }
}
