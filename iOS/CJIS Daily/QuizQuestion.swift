//
//  QuizQuestion.swift
//  CJIS Daily
//
//  Created by Ramon Dominguez on 12/9/25.
//
//
//  QuizQuestion.swift
//  CJIS Daily
//
import Foundation

struct QuizQuestion: Identifiable, Hashable, Codable {
    let id: UUID
    let prompt: String
    let choices: [String]
    let correctIndex: Int
    let explanation: String

    enum CodingKeys: String, CodingKey {
        case id, prompt, choices, correctIndex, explanation
    }

    init(
        id: UUID = UUID(),
        prompt: String,
        choices: [String],
        correctIndex: Int,
        explanation: String
    ) {
        precondition(!choices.isEmpty, "QuizQuestion must have at least one choice")
        precondition(choices.indices.contains(correctIndex), "correctIndex must be valid")

        self.id = id
        self.prompt = prompt
        self.choices = choices
        self.correctIndex = correctIndex
        self.explanation = explanation
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)

        // If id is missing in JSON, generate one
        self.id = (try? c.decode(UUID.self, forKey: .id)) ?? UUID()
        self.prompt = try c.decode(String.self, forKey: .prompt)
        self.choices = try c.decode([String].self, forKey: .choices)
        self.correctIndex = try c.decode(Int.self, forKey: .correctIndex)
        self.explanation = try c.decode(String.self, forKey: .explanation)

        guard !choices.isEmpty else {
            throw DecodingError.dataCorruptedError(forKey: .choices, in: c,
                debugDescription: "choices must not be empty")
        }
        guard choices.indices.contains(correctIndex) else {
            throw DecodingError.dataCorruptedError(forKey: .correctIndex, in: c,
                debugDescription: "correctIndex \(correctIndex) is out of bounds for \(choices.count) choices")
        }
    }
}
