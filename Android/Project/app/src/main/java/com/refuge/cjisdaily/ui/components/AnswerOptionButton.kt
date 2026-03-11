package com.refuge.cjisdaily.ui.components

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Close
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import com.refuge.cjisdaily.ui.theme.CJISBlue
import com.refuge.cjisdaily.ui.theme.CorrectGreen
import com.refuge.cjisdaily.ui.theme.WrongRed

enum class AnswerState { NORMAL, SELECTED, CORRECT, WRONG, DISABLED }

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AnswerOptionButton(
    text: String,
    state: AnswerState,
    onClick: () -> Unit
) {
    val (borderColor, indicatorColor, textAlpha) = when (state) {
        AnswerState.NORMAL -> Triple(MaterialTheme.colorScheme.onSurface.copy(alpha = 0.2f), Color.Transparent, 1f)
        AnswerState.SELECTED -> Triple(CJISBlue, CJISBlue, 1f)
        AnswerState.CORRECT -> Triple(CorrectGreen, CorrectGreen, 1f)
        AnswerState.WRONG -> Triple(WrongRed, WrongRed, 1f)
        AnswerState.DISABLED -> Triple(MaterialTheme.colorScheme.onSurface.copy(alpha = 0.1f), Color.Transparent, 0.4f)
    }

    Card(
        onClick = onClick,
        enabled = state == AnswerState.NORMAL || state == AnswerState.SELECTED,
        shape = RoundedCornerShape(14.dp),
        border = BorderStroke(1.5.dp, borderColor),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surface,
            disabledContainerColor = MaterialTheme.colorScheme.surface
        ),
        modifier = Modifier.fillMaxWidth()
    ) {
        Row(
            verticalAlignment = Alignment.CenterVertically,
            modifier = Modifier.padding(horizontal = 16.dp, vertical = 14.dp)
        ) {
            Surface(
                shape = CircleShape,
                color = indicatorColor,
                border = BorderStroke(1.5.dp, borderColor),
                modifier = Modifier.size(24.dp)
            ) {
                Box(contentAlignment = Alignment.Center) {
                    when (state) {
                        AnswerState.CORRECT -> Icon(Icons.Default.Check, null, tint = Color.White, modifier = Modifier.size(14.dp))
                        AnswerState.WRONG -> Icon(Icons.Default.Close, null, tint = Color.White, modifier = Modifier.size(14.dp))
                        else -> {}
                    }
                }
            }
            Spacer(Modifier.width(12.dp))
            Text(
                text,
                style = MaterialTheme.typography.bodyLarge,
                color = MaterialTheme.colorScheme.onSurface.copy(alpha = textAlpha)
            )
        }
    }
}
