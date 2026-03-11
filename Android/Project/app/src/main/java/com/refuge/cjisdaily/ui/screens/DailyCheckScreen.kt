package com.refuge.cjisdaily.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.refuge.cjisdaily.ui.components.AnswerOptionButton
import com.refuge.cjisdaily.ui.components.AnswerState
import com.refuge.cjisdaily.ui.theme.CJISBlue
import com.refuge.cjisdaily.ui.theme.CorrectGreen
import com.refuge.cjisdaily.ui.theme.WrongRed
import com.refuge.cjisdaily.viewmodel.CJISViewModel

@Composable
fun DailyCheckScreen(
    viewModel: CJISViewModel,
    onFinished: () -> Unit
) {
    val questions by viewModel.quizQuestions.collectAsState()
    val currentIndex by viewModel.currentQuestionIndex.collectAsState()
    val selectedAnswer by viewModel.selectedAnswerIndex.collectAsState()
    val submittedAnswer by viewModel.submittedAnswerIndex.collectAsState()
    val showExplanation by viewModel.showExplanation.collectAsState()
    val correctCount by viewModel.quizCorrectCount.collectAsState()
    val quizFinished by viewModel.quizFinished.collectAsState()

    LaunchedEffect(quizFinished) {
        if (quizFinished) onFinished()
    }

    val question = questions.getOrNull(currentIndex) ?: return
    val isSubmitted = submittedAnswer != null
    val isCorrect = submittedAnswer == question.correctIndex

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(MaterialTheme.colorScheme.background)
    ) {
        // Header
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 20.dp, vertical = 12.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                "Daily Check",
                style = MaterialTheme.typography.headlineSmall,
                color = CJISBlue
            )
            Text(
                "${currentIndex + 1} / ${questions.size}",
                style = MaterialTheme.typography.labelLarge,
                color = MaterialTheme.colorScheme.onBackground.copy(alpha = 0.6f)
            )
        }

        Column(
            modifier = Modifier
                .weight(1f)
                .verticalScroll(rememberScrollState())
                .padding(horizontal = 20.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            // Question card
            Card(
                shape = RoundedCornerShape(18.dp),
                colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
                elevation = CardDefaults.cardElevation(2.dp),
                modifier = Modifier.fillMaxWidth()
            ) {
                Text(
                    question.prompt,
                    style = MaterialTheme.typography.headlineSmall,
                    modifier = Modifier.padding(20.dp)
                )
            }

            // Answer options
            question.choices.forEachIndexed { index, choice ->
                val state = when {
                    !isSubmitted && selectedAnswer == index -> AnswerState.SELECTED
                    !isSubmitted && selectedAnswer != index -> AnswerState.NORMAL
                    index == question.correctIndex -> AnswerState.CORRECT
                    index == submittedAnswer -> AnswerState.WRONG
                    else -> AnswerState.DISABLED
                }
                AnswerOptionButton(
                    text = choice,
                    state = state,
                    onClick = { viewModel.selectAnswer(index) }
                )
            }

            // Result feedback
            if (isSubmitted) {
                Card(
                    shape = RoundedCornerShape(14.dp),
                    colors = CardDefaults.cardColors(
                        containerColor = if (isCorrect) CorrectGreen.copy(alpha = 0.1f)
                                         else WrongRed.copy(alpha = 0.1f)
                    ),
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Column(Modifier.padding(16.dp)) {
                        Text(
                            if (isCorrect) "Correct!" else "Not quite",
                            style = MaterialTheme.typography.labelLarge,
                            color = if (isCorrect) CorrectGreen else WrongRed
                        )
                        if (showExplanation && question.explanation.isNotBlank()) {
                            Spacer(Modifier.height(8.dp))
                            Text(
                                question.explanation,
                                style = MaterialTheme.typography.bodyMedium,
                                color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.8f)
                            )
                        }
                    }
                }
            }

            Spacer(Modifier.height(8.dp))
        }

        // Bottom action buttons
        Column(Modifier.padding(horizontal = 20.dp, vertical = 12.dp)) {
            if (!isSubmitted) {
                Button(
                    onClick = { viewModel.submitAnswer() },
                    enabled = selectedAnswer != null,
                    colors = ButtonDefaults.buttonColors(containerColor = CJISBlue),
                    shape = RoundedCornerShape(14.dp),
                    modifier = Modifier.fillMaxWidth().height(52.dp)
                ) {
                    Text("Submit Answer", color = Color.White, style = MaterialTheme.typography.labelLarge)
                }
            } else {
                val isLast = currentIndex == questions.size - 1
                Button(
                    onClick = { viewModel.nextQuestion() },
                    colors = ButtonDefaults.buttonColors(containerColor = CJISBlue),
                    shape = RoundedCornerShape(14.dp),
                    modifier = Modifier.fillMaxWidth().height(52.dp)
                ) {
                    Text(
                        if (isLast) "Finish" else "Next Question",
                        color = Color.White,
                        style = MaterialTheme.typography.labelLarge
                    )
                }
            }

            Spacer(Modifier.height(4.dp))
            Text(
                "Score so far: $correctCount / ${currentIndex + if (isSubmitted) 1 else 0}",
                style = MaterialTheme.typography.labelSmall,
                color = MaterialTheme.colorScheme.onBackground.copy(alpha = 0.5f),
                textAlign = TextAlign.Center,
                modifier = Modifier.fillMaxWidth()
            )
        }
    }
}
