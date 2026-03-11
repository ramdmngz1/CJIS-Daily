package com.refuge.cjisdaily.notifications

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import androidx.datastore.preferences.core.intPreferencesKey
import com.refuge.cjisdaily.viewmodel.dataStore
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Intent.ACTION_BOOT_COMPLETED) return
        CoroutineScope(Dispatchers.IO).launch {
            val prefs = context.dataStore.data.first()
            val hour = prefs[intPreferencesKey("reminder_hour")] ?: 9
            val minute = prefs[intPreferencesKey("reminder_minute")] ?: 0
            DailyReminderWorker.schedule(context, hour, minute)
        }
    }
}
