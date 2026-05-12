package com.refuge.cjisdaily.data

import android.content.Context
import com.google.gson.Gson
import com.google.gson.reflect.TypeToken
import com.refuge.cjisdaily.R
import java.time.LocalDate
import java.time.format.DateTimeFormatter

class DataRepository(private val context: Context) {

    private val gson = Gson()

    private val allTips: List<CjisTip> by lazy {
        val json = context.resources.openRawResource(R.raw.cjis_tips)
            .bufferedReader().use { it.readText() }
        val type = object : TypeToken<List<CjisTip>>() {}.type
        gson.fromJson(json, type)
    }

    private val quizSets: Map<Int, TipQuizSet> by lazy {
        val json = context.resources.openRawResource(R.raw.cjis_quizzes)
            .bufferedReader().use { it.readText() }
        val type = object : TypeToken<List<TipQuizSet>>() {}.type
        val sets: List<TipQuizSet> = gson.fromJson(json, type)
        sets.associateBy { it.tipId }
    }

    private val tipsWithQuizzes: List<CjisTip> by lazy {
        allTips.filter { quizSets.containsKey(it.id) }
    }

    fun tipsForToday(date: LocalDate = LocalDate.now(), count: Int = 5): List<CjisTip> {
        if (count <= 0 || tipsWithQuizzes.isEmpty()) return emptyList()

        val dayOfYear = date.dayOfYear
        // NOTE: ((dayOfYear - 1) * count) matches the iOS TipStore.tipsForToday formula so
        // both platforms produce the same pack on the same calendar day.
        val startIndex = ((dayOfYear - 1) * count).mod(tipsWithQuizzes.size)
        val target = minOf(count, tipsWithQuizzes.size)

        val results = mutableListOf<CjisTip>()
        val seenIds = mutableSetOf<Int>()
        for (i in 0 until tipsWithQuizzes.size) {
            if (results.size >= target) break
            val candidate = tipsWithQuizzes[(startIndex + i) % tipsWithQuizzes.size]
            if (seenIds.add(candidate.id)) {
                results.add(candidate)
            }
        }
        return results
    }

    fun questionsForTip(tipId: Int): List<QuizQuestion> =
        quizSets[tipId]?.questions ?: emptyList()

    fun todayKey(): String =
        LocalDate.now().format(DateTimeFormatter.ISO_LOCAL_DATE)
}
