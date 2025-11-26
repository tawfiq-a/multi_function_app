package com.example.test_alarm

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.net.Uri
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import android.app.NotificationChannel
import android.app.NotificationManager

class AlarmReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        val title = intent.getStringExtra("ALARM_TITLE") ?: "Alarm"
        val body = intent.getStringExtra("ALARM_BODY") ?: "Time to wake up!"
        val channelId = intent.getStringExtra("CHANNEL_ID") ?: "default_channel"

        showNotification(context, title, body, channelId)
    }

    private fun showNotification(context: Context, title: String, body: String, channelId: String) {
        val notificationManager = NotificationManagerCompat.from(context)

        //  Create Notification Channel
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val name = "Alarm Notifications"
            val descriptionText = "Channel for scheduled alarms"
            val importance = NotificationManager.IMPORTANCE_HIGH
            val channel = NotificationChannel(channelId, name, importance).apply {
                description = descriptionText

                // ---  Sound Configuration  ---

                val soundUri = Uri.parse("android.resource://${context.packageName}/raw/alarm_rington")
                val audioAttributes = AudioAttributes.Builder()
                    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                    .setUsage(AudioAttributes.USAGE_ALARM)
                    .build()
                setSound(soundUri, audioAttributes)
            }
            notificationManager.createNotificationChannel(channel)
        }

        //  Build the Notification
        val builder = NotificationCompat.Builder(context, channelId)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(title)
            .setContentText(body)
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setDefaults(NotificationCompat.DEFAULT_VIBRATE)
            .setAutoCancel(true)

        //  Display Notification
        notificationManager.notify(1, builder.build())
    }
}
