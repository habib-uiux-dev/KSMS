package com.kms.app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        createNotificationChannel()
    }

    /**
     * Makes sure `main_channel` exists before anything tries to post to it.
     *
     * The channel was previously created only by the awesome_notifications
     * plugin, from Dart, partway through startup. Anything arriving before
     * that - in particular a push handled by Firebase's own SDK while the app
     * is closed - had to post to a channel that might not exist yet, and
     * Android 8+ drops those rather than showing them. Creating it here, in
     * native code on the very first frame, removes the timing question.
     *
     * Idempotent: createNotificationChannel on an existing id is a no-op for
     * importance, so the plugin registering the same channel afterwards
     * changes nothing.
     */
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return

        val manager = getSystemService(NotificationManager::class.java) ?: return
        if (manager.getNotificationChannel(CHANNEL_ID) != null) return

        val channel = NotificationChannel(
            CHANNEL_ID,
            "Main Channel",
            NotificationManager.IMPORTANCE_HIGH,
        )
        channel.description = "App notifications"
        channel.enableVibration(true)

        manager.createNotificationChannel(channel)
    }

    private companion object {
        /** Must match AndroidManifest's default_notification_channel_id, the
         *  channelKey in AwesomeNotificationService, and the channel_id sent
         *  by PushSender. All four are the same string on purpose. */
        const val CHANNEL_ID = "main_channel"
    }
}
