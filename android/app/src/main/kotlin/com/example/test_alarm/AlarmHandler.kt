
package com.example.test_alarm

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.provider.Settings
import io.flutter.plugin.common.MethodChannel

class AlarmHandler(private val context: Context) {
    private val ALARM_REQUEST_CODE = 100

    fun setAlarm(call: io.flutter.plugin.common.MethodCall, result: MethodChannel.Result) {
        val timeInMillis = call.argument<Long>("timeInMillis")
        val title = call.argument<String>("title")
        val body = call.argument<String>("body")
        val channelId = call.argument<String>("channelId")

        if (timeInMillis != null && title != null && body != null && channelId != null) {
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            val intent = Intent(context, AlarmReceiver::class.java).apply {
                putExtra("ALARM_TITLE", title)
                putExtra("ALARM_BODY", body)
                putExtra("CHANNEL_ID", channelId)
            }

            val pendingIntent = PendingIntent.getBroadcast(
                context,
                ALARM_REQUEST_CODE,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                if (alarmManager.canScheduleExactAlarms()) {
                    alarmManager.setExactAndAllowWhileIdle(
                        AlarmManager.RTC_WAKEUP,
                        timeInMillis,
                        pendingIntent
                    )
                } else {
                    val settingsIntent = Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM)
                    context.startActivity(settingsIntent)
                }
            } else {
                alarmManager.setExactAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    timeInMillis,
                    pendingIntent
                )
            }
            result.success(true)
        } else {
            result.error("ARGUMENT_ERROR", "Missing alarm details", null)
        }
    }

    fun cancelAlarm(result: MethodChannel.Result) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(context, AlarmReceiver::class.java)
        val pendingIntent = PendingIntent.getBroadcast(
            context,
            ALARM_REQUEST_CODE,
            intent,
            PendingIntent.FLAG_IMMUTABLE
        )
        alarmManager.cancel(pendingIntent)
        result.success(true)
    }
}