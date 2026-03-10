//
//  AnswerOptionButton.swift
//  CJIS Daily
//
//  Created by Ramon Dominguez on 12/23/25.
//

import SwiftUI

/// Shared answer rendering state used by DailyCheckView (and any future quizzes).
enum AnswerOptionState: Equatable {
    case normal
    case selected
    case correct
    case wrong
    case disabled
}

struct AnswerOptionButton: View {
    let text: String
    let isDark: Bool
    let inkColor: Color
    let brandBlue: Color
    let state: AnswerOptionState
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 10) {

                Group {
                    switch state {
                    case .correct:
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    case .wrong:
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.red)
                    case .selected:
                        Image(systemName: "circle.inset.filled")
                            .foregroundColor(brandBlue)
                    default:
                        Image(systemName: "circle")
                            .foregroundColor(inkColor.opacity(0.45))
                    }
                }
                .font(.system(size: 17, weight: .semibold))
                .padding(.top, 1)

                Text(text)
                    .font(AppStyle.body(15))
                    .foregroundColor(foreground)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 0)
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 14)
            .background(background)
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(border, lineWidth: 1.2)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(accessibilityHint)
    }

    private var accessibilityLabel: String {
        switch state {
        case .correct: return "\(text). Correct answer."
        case .wrong:   return "\(text). Incorrect answer."
        case .selected: return "\(text). Selected."
        case .disabled: return text
        case .normal:  return text
        }
    }

    private var accessibilityHint: String {
        (state == .normal || state == .selected) ? "Double tap to select" : ""
    }

    private var background: Color {
        switch state {
        case .normal:
            return isDark ? Color.white.opacity(0.04) : Color.black.opacity(0.03)
        case .selected:
            return AppStyle.cjisBlueSoft.opacity(isDark ? 0.22 : 1.0)
        case .correct:
            return Color.green.opacity(isDark ? 0.22 : 0.16)
        case .wrong:
            return Color.red.opacity(isDark ? 0.18 : 0.12)
        case .disabled:
            return isDark ? Color.white.opacity(0.03) : Color.black.opacity(0.02)
        }
    }

    private var border: Color {
        switch state {
        case .normal:
            return inkColor.opacity(0.10)
        case .selected:
            return brandBlue.opacity(0.70)
        case .correct:
            return Color.green.opacity(0.55)
        case .wrong:
            return Color.red.opacity(0.50)
        case .disabled:
            return inkColor.opacity(0.06)
        }
    }

    private var foreground: Color {
        switch state {
        case .disabled:
            return inkColor.opacity(0.55)
        default:
            return inkColor.opacity(0.92)
        }
    }
}
