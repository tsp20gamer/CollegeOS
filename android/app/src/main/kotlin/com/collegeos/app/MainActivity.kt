package com.collegeos.app

import android.Manifest
import android.app.NotificationManager
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.OpenableColumns
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream
import java.util.Locale
import java.util.UUID

class MainActivity : FlutterActivity() {
    private var incomingBackupChannel: MethodChannel? = null
    private val pendingBackups = ArrayDeque<String>()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.collegeos.app/notifications",
        ).setMethodCallHandler { call, result ->
            try {
                when (call.method) {
                    "openNotificationSettings" -> {
                        val channelId = call.argument<String>("channelId")
                        val intent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && channelId != null) {
                            Intent(Settings.ACTION_CHANNEL_NOTIFICATION_SETTINGS).apply {
                                putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
                                putExtra(Settings.EXTRA_CHANNEL_ID, channelId)
                            }
                        } else {
                            Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                                data = Uri.parse("package:$packageName")
                            }
                        }
                        startActivity(intent)
                        result.success(null)
                    }
                    "getNotificationStatus" -> {
                        val notificationManager =
                            getSystemService(NOTIFICATION_SERVICE) as NotificationManager
                        val channelId = call.argument<String>("channelId")
                        val appNotificationsEnabled = notificationManager.areNotificationsEnabled()
                        val postPermissionGranted =
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                                checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) ==
                                    PackageManager.PERMISSION_GRANTED
                            } else {
                                appNotificationsEnabled
                            }
                        val channelEnabled =
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && channelId != null) {
                                notificationManager.getNotificationChannel(channelId)?.importance?.let {
                                    it != NotificationManager.IMPORTANCE_NONE
                                } ?: false
                            } else {
                                true
                            }
                        result.success(mapOf(
                            "postPermissionGranted" to postPermissionGranted,
                            "appNotificationsEnabled" to appNotificationsEnabled,
                            "channelEnabled" to channelEnabled,
                        ))
                    }
                    else -> result.notImplemented()
                }
            } catch (error: Exception) {
                result.error("notification_settings", error.message, null)
            }
        }

        incomingBackupChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            INCOMING_BACKUP_CHANNEL,
        ).also { channel ->
            channel.setMethodCallHandler { call, result ->
                when (call.method) {
                    "takePendingBackup" -> result.success(synchronized(pendingBackups) {
                        if (pendingBackups.isEmpty()) null else pendingBackups.removeFirst()
                    })
                    "acknowledgeBackup" -> {
                        val path = call.argument<String>("path")
                        synchronized(pendingBackups) { pendingBackups.remove(path) }
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
        }
        receiveBackupFrom(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        receiveBackupFrom(intent)
    }

    override fun onDestroy() {
        incomingBackupChannel?.setMethodCallHandler(null)
        incomingBackupChannel = null
        super.onDestroy()
    }

    private fun receiveBackupFrom(intent: Intent?) {
        val source = when (intent?.action) {
            Intent.ACTION_VIEW -> intent.data
            Intent.ACTION_SEND -> sharedStream(intent)
            else -> null
        } ?: return

        Thread {
            try {
                val cachedPath = cacheIncomingBackup(source)
                synchronized(pendingBackups) { pendingBackups.addLast(cachedPath) }
                runOnUiThread {
                    incomingBackupChannel?.invokeMethod("incomingBackup", cachedPath)
                }
            } catch (error: Exception) {
                runOnUiThread {
                    incomingBackupChannel?.invokeMethod(
                        "incomingBackupError",
                        error.message ?: "CollegeOS could not read that backup file.",
                    )
                }
            }
        }.start()
    }

    @Suppress("DEPRECATION")
    private fun sharedStream(intent: Intent): Uri? =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            intent.getParcelableExtra(Intent.EXTRA_STREAM, Uri::class.java)
        } else {
            intent.getParcelableExtra(Intent.EXTRA_STREAM)
        }

    private fun cacheIncomingBackup(uri: Uri): String {
        val displayName = displayName(uri)
            ?: uri.lastPathSegment?.substringAfterLast('/')
            ?: "CollegeOS_Backup.collegeos"
        if (!displayName.lowercase(Locale.ROOT).endsWith(".collegeos")) {
            throw IllegalArgumentException("Choose a file ending in .collegeos.")
        }

        val directory = File(cacheDir, "incoming_backups").apply { mkdirs() }
        directory.listFiles()?.forEach { file ->
            if (System.currentTimeMillis() - file.lastModified() > CACHE_MAX_AGE_MS) {
                file.delete()
            }
        }
        val safeName = displayName.replace(Regex("[^A-Za-z0-9._-]"), "_")
        val destination = File(directory, "${UUID.randomUUID()}_$safeName")
        val input = contentResolver.openInputStream(uri)
            ?: throw IllegalArgumentException("CollegeOS could not open that backup file.")

        try {
            input.use { source ->
                FileOutputStream(destination).use { output ->
                    val buffer = ByteArray(DEFAULT_BUFFER_SIZE)
                    var total = 0L
                    while (true) {
                        val count = source.read(buffer)
                        if (count < 0) break
                        total += count
                        if (total > MAX_BACKUP_BYTES) {
                            throw IllegalArgumentException("That backup is too large to import.")
                        }
                        output.write(buffer, 0, count)
                    }
                }
            }
        } catch (error: Exception) {
            destination.delete()
            throw error
        }
        return destination.absolutePath
    }

    private fun displayName(uri: Uri): String? {
        if (uri.scheme == "file") return uri.lastPathSegment
        return contentResolver.query(
            uri,
            arrayOf(OpenableColumns.DISPLAY_NAME),
            null,
            null,
            null,
        )?.use { cursor ->
            if (!cursor.moveToFirst()) return@use null
            val index = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
            if (index < 0) null else cursor.getString(index)
        }
    }

    companion object {
        private const val INCOMING_BACKUP_CHANNEL = "com.collegeos.app/incoming_backup"
        private const val MAX_BACKUP_BYTES = 100L * 1024L * 1024L
        private const val CACHE_MAX_AGE_MS = 24L * 60L * 60L * 1000L
    }
}
