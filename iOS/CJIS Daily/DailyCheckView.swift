//
//  DailyCheckView.swift
//  CJIS Daily
//
//  5-question check generated from today's 5 tips (1 question per tip).
//  Uses AnswerOptionState (shared) so this view is decoupled from legacy quiz screens.
//

import SwiftUI

struct DailyCheckView: View {
    let tips: [CJISTip]
    let onFinished: (_ correct: Int, _ total: Int) -> Void

    @Environment(\.dismiss) private var dismiss
    @AppStorage("themeMode") private var themeModeRaw: String = ThemeMode.light.rawValue

    @State private var currentIndex: Int = 0
    @State private var selectedIndex: Int? = nil
    @State private var submittedIndex: Int? = nil
    @State private var showExplanation: Bool = false

    @State private var correctCount: Int = 0

    private var isDark: Bool { ThemeMode(rawValue: themeModeRaw) == .dark }
    private var inkColor: Color { AppStyle.ink(isDark: isDark) }
    private var brandBlue: Color { AppStyle.cjisBlue }

    private var questions: [QuizQuestion] {
        // Deterministic: pick the first question for each tip.
        // TipStore is already filtering to tips that have questions, so this should always be 5.
        tips.compactMap { DailyQuizStore.shared.questions(for: $0.id).first }
    }

    private var currentQuestion: QuizQuestion? {
        guard !questions.isEmpty, questions.indices.contains(currentIndex) else { return nil }
        return questions[currentIndex]
    }

    private var hasNextQuestion: Bool {
        currentIndex < questions.count - 1
    }

    private var submitEnabled: Bool {
        selectedIndex != nil && submittedIndex == nil
    }

    var body: some View {
        ZStack {
            PaperBackground()

            VStack(alignment: .leading, spacing: 14) {

                HStack {
                    Text("Daily Check")
                        .font(AppStyle.titleSerif(22, weight: .semibold))
                        .foregroundColor(brandBlue)

                    Spacer()

                    Text(questions.isEmpty ? "0/0" : "\(currentIndex + 1)/\(questions.count)")
                        .font(AppStyle.body(13, weight: .semibold))
                        .foregroundColor(inkColor.opacity(0.6))
                        .accessibilityLabel(questions.isEmpty ? "No questions" : "Question \(currentIndex + 1) of \(questions.count)")
                }

                Rectangle()
                    .fill(AppStyle.cjisBlueSoft)
                    .frame(height: 1)
                    .padding(.bottom, 2)

                if let question = currentQuestion {
                    Text(question.prompt)
                        .font(AppStyle.body(16))
                        .foregroundColor(inkColor.opacity(0.88))
                        .fixedSize(horizontal: false, vertical: true)

                    VStack(spacing: 10) {
                        ForEach(question.choices.indices, id: \.self) { idx in
                            AnswerOptionButton(
                                text: question.choices[idx],
                                isDark: isDark,
                                inkColor: inkColor,
                                brandBlue: brandBlue,
                                state: optionState(for: idx, question: question)
                            ) {
                                handleSelection(idx)
                            }
                            .disabled(showExplanation)
                        }
                    }

                    if !showExplanation {
                        Button {
                            submitAnswer(for: question)
                        } label: {
                            Text("Submit Answer")
                                .font(AppStyle.body(15, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .fill(submitEnabled ? brandBlue : brandBlue.opacity(0.35))
                                )
                        }
                        .buttonStyle(.plain)
                        .disabled(!submitEnabled)
                        .padding(.top, 6)
                    }

                    if showExplanation, let submittedIndex {
                        let isCorrect = submittedIndex == question.correctIndex

                        Text(isCorrect ? "Correct" : "Not quite")
                            .font(AppStyle.body(14, weight: .semibold))
                            .foregroundColor(isCorrect ? .green : .red)
                            .padding(.top, 4)

                        Text(question.explanation)
                            .font(AppStyle.body(14))
                            .foregroundColor(inkColor.opacity(0.75))
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    if showExplanation {
                        Button {
                            advanceOrFinish()
                        } label: {
                            HStack(spacing: 8) {
                                Text(hasNextQuestion ? "Next Question" : "Finish")
                                    .font(AppStyle.body(15, weight: .semibold))
                                Image(systemName: hasNextQuestion ? "arrow.right" : "checkmark.circle.fill")
                                    .font(.system(size: 13, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 14)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(brandBlue)
                            )
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 6)
                    }
                } else {
                    AppCard(isDark: isDark) {
                        Text("No questions available for today.")
                            .font(AppStyle.body(15, weight: .semibold))
                            .foregroundColor(inkColor)
                    }
                }

                Spacer(minLength: 10)
            }
            .frame(maxWidth: AppStyle.contentMaxWidth, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 18)
        }
        .environment(\.colorScheme, isDark ? .dark : .light)
    }

    private func optionState(for idx: Int, question: QuizQuestion) -> AnswerOptionState {
        if !showExplanation {
            guard let selectedIndex else { return .normal }
            return idx == selectedIndex ? .selected : .normal
        }

        guard let submittedIndex else { return .disabled }

        if idx == question.correctIndex { return .correct }
        if idx == submittedIndex { return .wrong }
        return .disabled
    }

    private func handleSelection(_ idx: Int) {
        guard !showExplanation else { return }
        selectedIndex = idx
    }

    private func submitAnswer(for question: QuizQuestion) {
        guard let selectedIndex else { return }

        submittedIndex = selectedIndex
        showExplanation = true

        if selectedIndex == question.correctIndex {
            correctCount += 1
        }
    }

    private func advanceOrFinish() {
        if hasNextQuestion {
            currentIndex += 1
            selectedIndex = nil
            submittedIndex = nil
            showExplanation = false
        } else {
            onFinished(correctCount, questions.count)
            dismiss()
        }
    }
}
