package com.refuge.cjisdaily.viewmodel

import android.content.Context
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.booleanPreferencesKey
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.intPreferencesKey
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import com.google.gson.Gson
import com.refuge.cjisdaily.data.CjisTip
import com.refuge.cjisdaily.data.DataRepository
import com.refuge.cjisdaily.data.DailyPackProgress
import com.refuge.cjisdaily.data.DailyScore
import com.refuge.cjisdaily.data.QuizProgress
import com.refuge.cjisdaily.data.QuizQuestion
import com.refuge.cjisdaily.notifications.DailyReminderWorker
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch

val Context.dataStore: DataStore<Preferences> by preferencesDataStore(name = "cjis_daily_prefs")

private val KEY_DARK_MODE = booleanPreferencesKey("dark_mode")
private val KEY_REMINDER_HOUR = intPreferencesKey("reminder_hour")
private val KEY_REMINDER_MINUTE = intPreferencesKey("reminder_minute")
private val KEY_QUIZ_PROGRESS = stringPreferencesKey("quiz_progress_v2")
private val KEY_DAILY_PROGRESS = stringPreferencesKey("daily_pack_progress_v1")

class CJISViewModel(private val context: Context) : ViewModel() {

    private val repository = DataRepository(context)
    private val gson = Gson()

    private val _isDarkMode = MutableStateFlow(false)
    val isDarkMode: StateFlow<Boolean> = _isDarkMode

    private val _reminderHour = MutableStateFlow(9)
    val reminderHour: StateFlow<Int> = _reminderHour

    private val _reminderMinute = MutableStateFlow(0)
    val reminderMinute: StateFlow<Int> = _reminderMinute

    private val _todayTips = MutableStateFlow<List<CjisTip>>(emptyList())
    val todayTips: StateFlow<List<CjisTip>> = _todayTips

    private val _quizProgress = MutableStateFlow(QuizProgress())
    val quizProgress: StateFlow<QuizProgress> = _quizProgress

    private val _dailyProgress = MutableStateFlow(DailyPackProgress())
    val dailyProgress: StateFlow<DailyPackProgress> = _dailyProgress

    // Quiz state
    private val _quizQuestions = MutableStateFlow<List<QuizQuestion>>(emptyList())
    val quizQuestions: StateFlow<List<QuizQuestion>> = _quizQuestions

    private val _currentQuestionIndex = MutableStateFlow(0)
    val currentQuestionIndex: StateFlow<Int> = _currentQuestionIndex

    private val _selectedAnswerIndex = MutableStateFlow<Int?>(null)
    val selectedAnswerIndex: StateFlow<Int?> = _selectedAnswerIndex

    private val _submittedAnswerIndex = MutableStateFlow<Int?>(null)
    val submittedAnswerIndex: StateFlow<Int?> = _submittedAnswerIndex

    private val _showExplanation = MutableStateFlow(false)
    val showExplanation: StateFlow<Boolean> = _showExplanation

    private val _quizCorrectCount = MutableStateFlow(0)
    val quizCorrectCount: StateFlow<Int> = _quizCorrectCount

    private val _quizFinished = MutableStateFlow(false)
    val quizFinished: StateFlow<Boolean> = _quizFinished

    init {
        viewModelScope.launch {
            val prefs = context.dataStore.data.first()
            _isDarkMode.value = prefs[KEY_DARK_MODE] ?: false
            _reminderHour.value = prefs[KEY_REMINDER_HOUR] ?: 9
            _reminderMinute.value = prefs[KEY_REMINDER_MINUTE] ?: 0

            prefs[KEY_QUIZ_PROGRESS]?.let { json ->
                _quizProgress.value = gson.fromJson(json, QuizProgress::class.java)
            }

            val todayKey = repository.todayKey()
            prefs[KEY_DAILY_PROGRESS]?.let { json ->
                val saved = gson.fromJson(json, DailyPackProgress::class.java)
                _dailyProgress.value = if (saved.dayKey == todayKey) saved
                                       else DailyPackProgress(dayKey = todayKey)
            } ?: run {
                _dailyProgress.value = DailyPackProgress(dayKey = todayKey)
            }

            _todayTips.value = repository.tipsForToday()
        }
    }

    fun setDarkMode(enabled: Boolean) {
        _isDarkMode.value = enabled
        viewModelScope.launch {
            context.dataStore.edit { it[KEY_DARK_MODE] = enabled }
        }
    }

    fun saveReminder(hour: Int, minute: Int) {
        _reminderHour.value = hour
        _reminderMinute.value = minute
        viewModelScope.launch {
            context.dataStore.edit {
                it[KEY_REMINDER_HOUR] = hour
                it[KEY_REMINDER_MINUTE] = minute
            }
        }
        DailyReminderWorker.schedule(context, hour, minute)
    }

    fun startDailyCheck() {
        val tips = _todayTips.value
        val questions = tips.mapNotNull { tip ->
            repository.questionsForTip(tip.id).firstOrNull()
        }
        _quizQuestions.value = questions
        _currentQuestionIndex.value = 0
        _selectedAnswerIndex.value = null
        _submittedAnswerIndex.value = null
        _showExplanation.value = false
        _quizCorrectCount.value = 0
        _quizFinished.value = false
    }

    fun selectAnswer(index: Int) {
        if (_submittedAnswerIndex.value == null) {
            _selectedAnswerIndex.value = index
        }
    }

    fun submitAnswer() {
        val selected = _selectedAnswerIndex.value ?: return
        _submittedAnswerIndex.value = selected
        _showExplanation.value = true
        val question = _quizQuestions.value.getOrNull(_currentQuestionIndex.value) ?: return
        if (selected == question.correctIndex) {
            _quizCorrectCount.value++
        }
    }

    fun nextQuestion() {
        val nextIndex = _currentQuestionIndex.value + 1
        if (nextIndex >= _quizQuestions.value.size) {
            finishQuiz()
        } else {
            _currentQuestionIndex.value = nextIndex
            _selectedAnswerIndex.value = null
            _submittedAnswerIndex.value = null
            _showExplanation.value = false
        }
    }

    private fun finishQuiz() {
        _quizFinished.value = true
        val correct = _quizCorrectCount.value
        val total = _quizQuestions.value.size
        val todayKey = repository.todayKey()

        // Update daily progress
        val newDaily = DailyPackProgress(
            dayKey = todayKey,
            dailyCheckCompleted = true,
            score = DailyScore(correct, total)
        )
        _dailyProgress.value = newDaily
        viewModelScope.launch {
            context.dataStore.edit { it[KEY_DAILY_PROGRESS] = gson.toJson(newDaily) }
        }

        // Update lifetime progress (no double-counting)
        val current = _quizProgress.value
        if (current.lastScoreRecordedDayKey != todayKey) {
            val updated = current.copy(
                lifetimeCorrect = current.lifetimeCorrect + correct,
                lifetimeAnswered = current.lifetimeAnswered + total,
                streakCount = current.streakCount + 1,
                lastScoreRecordedDayKey = todayKey
            )
            _quizProgress.value = updated
            viewModelScope.launch {
                context.dataStore.edit { it[KEY_QUIZ_PROGRESS] = gson.toJson(updated) }
            }
        }
    }

    class Factory(private val context: Context) : ViewModelProvider.Factory {
        override fun <T : ViewModel> create(modelClass: Class<T>): T {
            @Suppress("UNCHECKED_CAST")
            return CJISViewModel(context.applicationContext) as T
        }
    }
}
