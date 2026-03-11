package com.refuge.cjisdaily.data

data class CjisTip(
    val id: Int,
    val title: String,
    val shortText: String,
    val longText: String,
    val section: String
)

data class QuizQuestion(
    val prompt: String,
    val choices: List<String>,
    val correctIndex: Int,
    val explanation: String
)

data class TipQuizSet(
    val tipId: Int,
    val questions: List<QuizQuestion>
)

data class DailyScore(
    val correct: Int,
    val total: Int
) {
    val percentage: Int get() = if (total == 0) 0 else (correct * 100 / total)
}

data class QuizProgress(
    val streakCount: Int = 0,
    val lifetimeCorrect: Int = 0,
    val lifetimeAnswered: Int = 0,
    val lastScoreRecordedDayKey: String = ""
)

data class DailyPackProgress(
    val dayKey: String = "",
    val dailyCheckCompleted: Boolean = false,
    val score: DailyScore = DailyScore(0, 0)
)
