package com.refuge.cjisdaily.ui.theme

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable

private val LightColorScheme = lightColorScheme(
    primary = CJISBlue,
    background = LightBackground,
    surface = LightCard,
    onBackground = LightInk,
    onSurface = LightInk,
    onPrimary = DarkInk
)

private val DarkColorScheme = darkColorScheme(
    primary = CJISBlue,
    background = DarkBackground,
    surface = DarkCard,
    onBackground = DarkInk,
    onSurface = DarkInk,
    onPrimary = DarkInk
)

@Composable
fun CJISDailyTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    content: @Composable () -> Unit
) {
    val colorScheme = if (darkTheme) DarkColorScheme else LightColorScheme
    MaterialTheme(
        colorScheme = colorScheme,
        typography = Typography,
        content = content
    )
}
