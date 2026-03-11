package com.refuge.cjisdaily.ui.screens

import androidx.compose.animation.AnimatedContent
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
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.ArrowForward
import androidx.compose.material.icons.filled.ExpandLess
import androidx.compose.material.icons.filled.ExpandMore
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.refuge.cjisdaily.ui.theme.CJISBlue
import com.refuge.cjisdaily.viewmodel.CJISViewModel

@Composable
fun DailyPackScreen(
    viewModel: CJISViewModel,
    onStartQuiz: () -> Unit,
    onViewResults: () -> Unit,
    onOpenSettings: () -> Unit
) {
    val tips by viewModel.todayTips.collectAsState()
    val dailyProgress by viewModel.dailyProgress.collectAsState()

    var currentTipIndex by remember { mutableStateOf(0) }
    var showLongText by remember { mutableStateOf(false) }

    val currentTip = tips.getOrNull(currentTipIndex)

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(MaterialTheme.colorScheme.background)
    ) {
        // Header
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 8.dp, vertical = 4.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            IconButton(onClick = onOpenSettings) {
                Icon(Icons.Default.Settings, contentDescription = "Settings", tint = MaterialTheme.colorScheme.onBackground)
            }
            Text(
                "CJIS DAILY",
                style = MaterialTheme.typography.labelLarge,
                color = CJISBlue
            )
            // placeholder for symmetry
            IconButton(onClick = {}) {}
        }

        // Progress indicator
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 20.dp),
            horizontalArrangement = Arrangement.Center
        ) {
            tips.forEachIndexed { index, _ ->
                val isActive = index == currentTipIndex
                Card(
                    shape = RoundedCornerShape(50),
                    colors = CardDefaults.cardColors(
                        containerColor = if (isActive) CJISBlue else CJISBlue.copy(alpha = 0.2f)
                    ),
                    modifier = Modifier
                        .weight(1f)
                        .height(4.dp)
                        .padding(horizontal = 2.dp)
                ) {}
            }
        }

        Spacer(Modifier.height(4.dp))

        AnimatedContent(
            targetState = currentTipIndex,
            label = "tip"
        ) { tipIndex ->
            val tip = tips.getOrNull(tipIndex)
            Column(
                modifier = Modifier
                    .weight(1f)
                    .verticalScroll(rememberScrollState())
                    .padding(horizontal = 20.dp, vertical = 8.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                tip?.let {
                    Text(
                        "Tip ${tipIndex + 1} of ${tips.size}",
                        style = MaterialTheme.typography.labelSmall,
                        color = MaterialTheme.colorScheme.onBackground.copy(alpha = 0.5f)
                    )

                    Card(
                        shape = RoundedCornerShape(18.dp),
                        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
                        elevation = CardDefaults.cardElevation(2.dp),
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Column(Modifier.padding(20.dp)) {
                            Text(it.title, style = MaterialTheme.typography.headlineMedium, color = CJISBlue)
                            Spacer(Modifier.height(12.dp))
                            Text(it.shortText, style = MaterialTheme.typography.bodyLarge)

                            if (it.longText.isNotBlank()) {
                                Spacer(Modifier.height(8.dp))
                                TextButton(
                                    onClick = { showLongText = !showLongText },
                                    contentPadding = androidx.compose.foundation.layout.PaddingValues(0.dp)
                                ) {
                                    Icon(
                                        if (showLongText) Icons.Default.ExpandLess else Icons.Default.ExpandMore,
                                        contentDescription = null,
                                        tint = CJISBlue
                                    )
                                    Text(
                                        if (showLongText) "Show Less" else "Read More",
                                        color = CJISBlue,
                                        style = MaterialTheme.typography.labelMedium
                                    )
                                }
                                if (showLongText) {
                                    Text(it.longText, style = MaterialTheme.typography.bodyMedium)
                                }
                            }
                        }
                    }

                    if (it.section.isNotBlank()) {
                        Text(
                            "CJIS Policy: ${it.section}",
                            style = MaterialTheme.typography.labelSmall,
                            color = MaterialTheme.colorScheme.onBackground.copy(alpha = 0.5f)
                        )
                    }
                }
            }
        }

        // Navigation + action row
        Column(
            modifier = Modifier.padding(horizontal = 20.dp, vertical = 12.dp),
            verticalArrangement = Arrangement.spacedBy(10.dp)
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                IconButton(
                    onClick = { if (currentTipIndex > 0) { currentTipIndex--; showLongText = false } },
                    enabled = currentTipIndex > 0
                ) {
                    Icon(Icons.Default.ArrowBack, contentDescription = "Previous", tint = if (currentTipIndex > 0) CJISBlue else Color.Gray)
                }

                Text(
                    "${currentTipIndex + 1} / ${tips.size}",
                    style = MaterialTheme.typography.labelLarge,
                    color = MaterialTheme.colorScheme.onBackground,
                    modifier = Modifier.align(Alignment.CenterVertically)
                )

                IconButton(
                    onClick = { if (currentTipIndex < tips.size - 1) { currentTipIndex++; showLongText = false } },
                    enabled = currentTipIndex < tips.size - 1
                ) {
                    Icon(Icons.Default.ArrowForward, contentDescription = "Next", tint = if (currentTipIndex < tips.size - 1) CJISBlue else Color.Gray)
                }
            }

            if (currentTipIndex == tips.size - 1) {
                if (dailyProgress.dailyCheckCompleted) {
                    OutlinedButton(
                        onClick = onViewResults,
                        shape = RoundedCornerShape(14.dp),
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Text("View Results", color = CJISBlue)
                    }
                    Text(
                        "Completed for today",
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onBackground.copy(alpha = 0.5f),
                        textAlign = TextAlign.Center,
                        modifier = Modifier.fillMaxWidth()
                    )
                } else {
                    Button(
                        onClick = {
                            viewModel.startDailyCheck()
                            onStartQuiz()
                        },
                        colors = ButtonDefaults.buttonColors(containerColor = CJISBlue),
                        shape = RoundedCornerShape(14.dp),
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(52.dp)
                    ) {
                        Text("Start Daily Check", color = Color.White, style = MaterialTheme.typography.labelLarge)
                    }
                }
            }
        }
    }
}
