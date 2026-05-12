package com.refuge.cjisdaily

import android.Manifest
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.activity.result.contract.ActivityResultContracts
import androidx.core.content.ContextCompat
import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen
import androidx.compose.animation.AnimatedContent
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.systemBarsPadding
import androidx.compose.material3.Surface
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.lifecycle.viewmodel.compose.viewModel
import com.refuge.cjisdaily.ui.screens.CJISSettingsScreen
import com.refuge.cjisdaily.ui.screens.DailyCheckScreen
import com.refuge.cjisdaily.ui.screens.DailyPackScreen
import com.refuge.cjisdaily.ui.screens.ResultsScreen
import com.refuge.cjisdaily.ui.theme.CJISDailyTheme
import com.refuge.cjisdaily.viewmodel.CJISViewModel

private enum class Screen { PACK, QUIZ, RESULTS, SETTINGS }

class MainActivity : ComponentActivity() {

    private val notificationPermissionLauncher = registerForActivityResult(
        ActivityResultContracts.RequestPermission()
    ) { /* permission result handled silently */ }

    override fun onCreate(savedInstanceState: Bundle?) {
        installSplashScreen()
        super.onCreate(savedInstanceState)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            val alreadyGranted = ContextCompat.checkSelfPermission(
                this,
                Manifest.permission.POST_NOTIFICATIONS
            ) == PackageManager.PERMISSION_GRANTED
            if (!alreadyGranted) {
                notificationPermissionLauncher.launch(Manifest.permission.POST_NOTIFICATIONS)
            }
        }
        enableEdgeToEdge()
        setContent {
            val vm: CJISViewModel = viewModel(factory = CJISViewModel.Factory(applicationContext))
            val isDark by vm.isDarkMode.collectAsState()
            var screen by remember { mutableStateOf(Screen.PACK) }

            CJISDailyTheme(darkTheme = isDark) {
                Surface(
                    modifier = Modifier
                        .fillMaxSize()
                        .systemBarsPadding()
                ) {
                    AnimatedContent(targetState = screen, label = "screen") { current ->
                        when (current) {
                            Screen.PACK -> DailyPackScreen(
                                viewModel = vm,
                                onStartQuiz = { screen = Screen.QUIZ },
                                onViewResults = { screen = Screen.RESULTS },
                                onOpenSettings = { screen = Screen.SETTINGS }
                            )
                            Screen.QUIZ -> DailyCheckScreen(
                                viewModel = vm,
                                onFinished = { screen = Screen.RESULTS }
                            )
                            Screen.RESULTS -> ResultsScreen(
                                viewModel = vm,
                                onDone = { screen = Screen.PACK }
                            )
                            Screen.SETTINGS -> CJISSettingsScreen(
                                viewModel = vm,
                                onClose = { screen = Screen.PACK }
                            )
                        }
                    }
                }
            }
        }
    }
}
