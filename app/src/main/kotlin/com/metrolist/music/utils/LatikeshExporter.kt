/**
 * Metrolist Project (C) 2026
 * Licensed under GPL-3.0 | See git history for contributors
 */

package com.metrolist.music.utils

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.ContentValues
import android.content.Context
import android.net.ConnectivityManager
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import android.widget.Toast
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.getSystemService
import com.metrolist.innertube.YouTube
import com.metrolist.music.R
import com.metrolist.music.constants.AudioQuality
import com.metrolist.music.constants.AudioQualityKey
import com.metrolist.music.extensions.toEnum
import com.metrolist.music.models.MediaMetadata
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import okhttp3.OkHttpClient
import okhttp3.Request
import timber.log.Timber
import java.io.File
import java.io.FileOutputStream
import java.util.concurrent.atomic.AtomicInteger

/**
 * Utility object responsible for exporting audio tracks to public device storage.
 */
object LatikeshExporter {
    private const val TAG = "LatikeshExporter"
    private const val CHANNEL_ID = "audio_export_channel"
    private val notificationIdCounter = AtomicInteger(2000)

    private val exportScope = CoroutineScope(SupervisorJob() + Dispatchers.IO)

    private val httpClient = OkHttpClient.Builder()
        .proxy(YouTube.proxy)
        .build()

    /**
     * Creates the notification channel for audio export status updates.
     *
     * @param context Application context.
     */
    private fun createNotificationChannel(context: Context) {
        val name = "Audio Export"
        val descriptionText = "Notifications for exported music files"
        val importance = NotificationManager.IMPORTANCE_LOW
        val channel = NotificationChannel(CHANNEL_ID, name, importance).apply {
            description = descriptionText
        }
        val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
        notificationManager?.createNotificationChannel(channel)
    }

    /**
     * Safely posts a system notification catching any potential permission exception.
     *
     * @param manager Notification manager instance.
     * @param id Unique notification ID.
     * @param notification Notification object to post.
     */
    private fun safeNotify(manager: NotificationManagerCompat, id: Int, notification: Notification) {
        try {
            manager.notify(id, notification)
        } catch (e: SecurityException) {
            Timber.tag(TAG).w(e, "Notification permission missing")
        } catch (e: Exception) {
            Timber.tag(TAG).e(e, "Failed to post notification")
        }
    }

    /**
     * Checks if an audio file with the specified filename already exists in public storage (`Music/Metrolist`).
     *
     * @param context Application context.
     * @param fileName Target filename to check.
     * @return True if file exists and has size greater than 0, false otherwise.
     */
    private fun isAudioFileAlreadyExported(context: Context, fileName: String): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val projection = arrayOf(MediaStore.MediaColumns._ID)
            val selection = "${MediaStore.MediaColumns.DISPLAY_NAME} = ? AND ${MediaStore.MediaColumns.RELATIVE_PATH} LIKE ?"
            val selectionArgs = arrayOf(fileName, "%Music/Metrolist%")
            val cursor = context.contentResolver.query(
                MediaStore.Audio.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY),
                projection,
                selection,
                selectionArgs,
                null
            )
            cursor?.use { it.count > 0 } ?: false
        } else {
            val musicDir = File(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_MUSIC), "Metrolist")
            val targetFile = File(musicDir, fileName)
            targetFile.exists() && targetFile.length() > 0
        }
    }

    /**
     * Exports a song to public device storage (`Music/Metrolist`) asynchronously with live progress notifications.
     *
     * @param context Application or UI context.
     * @param mediaMetadata Track metadata to export.
     */
    fun exportToPublicStorage(
        context: Context,
        mediaMetadata: MediaMetadata,
    ) {
        val appContext = context.applicationContext
        val notifId = notificationIdCounter.incrementAndGet()

        createNotificationChannel(appContext)

        Toast.makeText(appContext, R.string.exporting_audio, Toast.LENGTH_SHORT).show()

        exportScope.launch {
            val notificationManager = NotificationManagerCompat.from(appContext)
            val notifBuilder = NotificationCompat.Builder(appContext, CHANNEL_ID)
                .setSmallIcon(R.drawable.download)
                .setContentTitle(mediaMetadata.title)
                .setContentText(appContext.getString(R.string.exporting_audio))
                .setPriority(NotificationCompat.PRIORITY_LOW)
                .setOngoing(true)
                .setProgress(100, 0, true)

            try {
                safeNotify(notificationManager, notifId, notifBuilder.build())

                val connectivityManager = appContext.getSystemService<ConnectivityManager>()
                    ?: throw IllegalStateException("ConnectivityManager unavailable")

                val qualityPref = appContext.dataStore.data.first()[AudioQualityKey]
                val audioQuality = qualityPref.toEnum(AudioQuality.AUTO)

                val playbackResult = InnerTubeXPlayer.playerResponseForPlayback(
                    videoId = mediaMetadata.id,
                    audioQuality = audioQuality,
                    connectivityManager = connectivityManager,
                )

                val playbackData = playbackResult.getOrThrow()
                val exportFormatPref = appContext.dataStore.data.first()[com.metrolist.music.constants.ExportFormatKey]
                val exportFormat = exportFormatPref.toEnum(com.metrolist.music.constants.ExportFormat.M4A)

                val mimeType = playbackData.format.mimeType.orEmpty().ifBlank { "audio/mpeg" }
                val isServerMp3 = mimeType.contains("mpeg") || mimeType.contains("mp3")
                val extension = if (exportFormat == com.metrolist.music.constants.ExportFormat.MP3) {
                    ".mp3"
                } else if (isServerMp3) {
                    ".mp3"
                } else if (mimeType.contains("mp4") || mimeType.contains("m4a")) {
                    ".m4a"
                } else {
                    ".mp3"
                }

                val sanitizedTitle = mediaMetadata.title.replace(Regex("[\\\\/:*?\"<>|]"), "_")
                val primaryArtist = mediaMetadata.artists.firstOrNull()?.name ?: ""
                val sanitizedArtist = primaryArtist.replace(Regex("[\\\\/:*?\"<>|]"), "_")
                val fileName = if (sanitizedArtist.isNotBlank()) "$sanitizedTitle - $sanitizedArtist$extension" else "$sanitizedTitle$extension"

                // Check if file already exists in public storage
                if (isAudioFileAlreadyExported(appContext, fileName)) {
                    notifBuilder
                        .setContentText(appContext.getString(R.string.already_exported_to_storage))
                        .setProgress(0, 0, false)
                        .setOngoing(false)
                    safeNotify(notificationManager, notifId, notifBuilder.build())

                    withContext(Dispatchers.Main) {
                        Toast.makeText(appContext, R.string.already_exported_to_storage, Toast.LENGTH_LONG).show()
                    }
                    return@launch
                }

                val requestBuilder = Request.Builder().url(playbackData.streamUrl)
                playbackData.streamHeaders.forEach { (key, value) ->
                    requestBuilder.header(key, value)
                }

                val response = httpClient.newCall(requestBuilder.build()).execute()
                if (!response.isSuccessful) {
                    throw IllegalStateException("HTTP ${response.code} downloading audio stream")
                }

                val body = response.body
                val contentLength = body.contentLength()

                val relativePath = Environment.DIRECTORY_MUSIC + "/Metrolist"

                val outputStream = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    val resolver = appContext.contentResolver
                    val contentValues = ContentValues().apply {
                        put(MediaStore.MediaColumns.DISPLAY_NAME, fileName)
                        put(MediaStore.MediaColumns.MIME_TYPE, if (extension == ".mp3") "audio/mpeg" else "audio/mp4")
                        put(MediaStore.MediaColumns.RELATIVE_PATH, relativePath)
                        put(MediaStore.MediaColumns.IS_PENDING, 1)
                    }

                    val collection = MediaStore.Audio.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
                    val destUri = resolver.insert(collection, contentValues)
                        ?: throw IllegalStateException("Failed to create destination in MediaStore")

                    val stream = resolver.openOutputStream(destUri)
                        ?: throw IllegalStateException("Failed to open output stream")

                    Pair(stream) {
                        val complete = ContentValues().apply { put(MediaStore.MediaColumns.IS_PENDING, 0) }
                        resolver.update(destUri, complete, null, null)
                    }
                } else {
                    val musicDir = File(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_MUSIC), "Metrolist")
                    if (!musicDir.exists()) {
                        musicDir.mkdirs()
                    }
                    val targetFile = File(musicDir, fileName)
                    Pair(FileOutputStream(targetFile)) {}
                }

                outputStream.first.use { out ->
                    body.byteStream().use { input ->
                        val buffer = ByteArray(16 * 1024)
                        var bytesRead: Int
                        var totalBytesRead = 0L
                        var lastProgress = 0

                        while (input.read(buffer).also { bytesRead = it } != -1) {
                            out.write(buffer, 0, bytesRead)
                            totalBytesRead += bytesRead

                            if (contentLength > 0) {
                                val progress = ((totalBytesRead * 100) / contentLength).toInt()
                                if (progress >= lastProgress + 5) {
                                    lastProgress = progress
                                    notifBuilder.setProgress(100, progress, false)
                                    safeNotify(notificationManager, notifId, notifBuilder.build())
                                }
                            }
                        }
                    }
                }
                outputStream.second()

                notifBuilder
                    .setContentText(appContext.getString(R.string.exported_to_storage))
                    .setProgress(0, 0, false)
                    .setOngoing(false)
                safeNotify(notificationManager, notifId, notifBuilder.build())

                withContext(Dispatchers.Main) {
                    Toast.makeText(appContext, R.string.exported_to_storage, Toast.LENGTH_LONG).show()
                }
            } catch (e: Exception) {
                Timber.tag(TAG).e(e, "Failed to export audio file")
                try {
                    notificationManager.cancel(notifId)
                } catch (_: Exception) {}
                withContext(Dispatchers.Main) {
                    Toast.makeText(appContext, R.string.export_audio_failed, Toast.LENGTH_SHORT).show()
                }
            }
        }
    }

    /**
     * Exports a trimmed A-B loop segment of a song to public storage (`Music/Metrolist`).
     *
     * @param context Application or UI context.
     * @param mediaMetadata Track metadata to export.
     * @param startMs Start timestamp in milliseconds (Point A).
     * @param endMs End timestamp in milliseconds (Point B).
     */
    fun exportTrimmedToPublicStorage(
        context: Context,
        mediaMetadata: MediaMetadata,
        startMs: Long,
        endMs: Long,
    ) {
        val appContext = context.applicationContext
        val notifId = notificationIdCounter.incrementAndGet()

        createNotificationChannel(appContext)
        Toast.makeText(appContext, R.string.exporting_audio, Toast.LENGTH_SHORT).show()

        exportScope.launch {
            val notificationManager = NotificationManagerCompat.from(appContext)
            val notifBuilder = NotificationCompat.Builder(appContext, CHANNEL_ID)
                .setSmallIcon(R.drawable.download)
                .setContentTitle("${mediaMetadata.title} (A-B Clip)")
                .setContentText(appContext.getString(R.string.exporting_audio))
                .setPriority(NotificationCompat.PRIORITY_LOW)
                .setOngoing(true)
                .setProgress(100, 0, true)

            try {
                safeNotify(notificationManager, notifId, notifBuilder.build())

                val connectivityManager = appContext.getSystemService<ConnectivityManager>()
                    ?: throw IllegalStateException("ConnectivityManager unavailable")

                val qualityPref = appContext.dataStore.data.first()[AudioQualityKey]
                val audioQuality = qualityPref.toEnum(AudioQuality.AUTO)

                val playbackResult = InnerTubeXPlayer.playerResponseForPlayback(
                    videoId = mediaMetadata.id,
                    audioQuality = audioQuality,
                    connectivityManager = connectivityManager,
                )

                val playbackData = playbackResult.getOrThrow()

                val startFormatted = formatPreciseTime(startMs).replace(":", "_")
                val endFormatted = formatPreciseTime(endMs).replace(":", "_")

                val sanitizedTitle = mediaMetadata.title.replace(Regex("[\\\\/:*?\"<>|]"), "_")
                val primaryArtist = mediaMetadata.artists.firstOrNull()?.name ?: ""
                val sanitizedArtist = primaryArtist.replace(Regex("[\\\\/:*?\"<>|]"), "_")
                val baseFileName = if (sanitizedArtist.isNotBlank()) {
                    "$sanitizedTitle - $sanitizedArtist [$startFormatted to $endFormatted]"
                } else {
                    "$sanitizedTitle [$startFormatted to $endFormatted]"
                }

                val exportFormatPref = appContext.dataStore.data.first()[com.metrolist.music.constants.ExportFormatKey]
                val exportFormat = exportFormatPref.toEnum(com.metrolist.music.constants.ExportFormat.M4A)
                val targetExtension = if (exportFormat == com.metrolist.music.constants.ExportFormat.MP3) ".mp3" else ".m4a"

                val fileName = "$baseFileName$targetExtension"

                // Check if file already exists in public storage
                if (isAudioFileAlreadyExported(appContext, fileName)) {
                    notifBuilder
                        .setContentText(appContext.getString(R.string.already_exported_to_storage))
                        .setProgress(0, 0, false)
                        .setOngoing(false)
                    safeNotify(notificationManager, notifId, notifBuilder.build())

                    withContext(Dispatchers.Main) {
                        Toast.makeText(appContext, R.string.already_exported_to_storage, Toast.LENGTH_LONG).show()
                    }
                    return@launch
                }

                // Download full audio stream to temporary cache file
                val tempFile = File(appContext.cacheDir, "temp_raw_${System.currentTimeMillis()}.tmp")
                val tempOutFile = File(appContext.cacheDir, "temp_trimmed_${System.currentTimeMillis()}.m4a")

                val requestBuilder = Request.Builder().url(playbackData.streamUrl)
                playbackData.streamHeaders.forEach { (key, value) ->
                    requestBuilder.header(key, value)
                }

                val response = httpClient.newCall(requestBuilder.build()).execute()
                if (!response.isSuccessful) {
                    throw IllegalStateException("HTTP ${response.code} downloading audio stream")
                }

                response.body.byteStream().use { input ->
                    FileOutputStream(tempFile).use { out ->
                        input.copyTo(out)
                    }
                }

                // Trim audio file using MediaExtractor and MediaMuxer
                var trimmedSuccessfully = false
                try {
                    val extractor = android.media.MediaExtractor()
                    extractor.setDataSource(tempFile.absolutePath)

                    var trackIndex = -1
                    var format: android.media.MediaFormat? = null
                    for (i in 0 until extractor.trackCount) {
                        val trackFormat = extractor.getTrackFormat(i)
                        val mime = trackFormat.getString(android.media.MediaFormat.KEY_MIME).orEmpty()
                        if (mime.startsWith("audio/")) {
                            trackIndex = i
                            format = trackFormat
                            extractor.selectTrack(i)
                            break
                        }
                    }

                    if (trackIndex >= 0 && format != null) {
                        val muxer = android.media.MediaMuxer(
                            tempOutFile.absolutePath,
                            android.media.MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4
                        )
                        val muxerTrackIndex = muxer.addTrack(format)
                        muxer.start()

                        val startUs = startMs * 1000L
                        val endUs = endMs * 1000L

                        extractor.seekTo(startUs, android.media.MediaExtractor.SEEK_TO_PREVIOUS_SYNC)

                        val maxBufferSize = if (format.containsKey(android.media.MediaFormat.KEY_MAX_INPUT_SIZE)) {
                            format.getInteger(android.media.MediaFormat.KEY_MAX_INPUT_SIZE)
                        } else 512 * 1024

                        val buffer = java.nio.ByteBuffer.allocateDirect(maxBufferSize)
                        val bufferInfo = android.media.MediaCodec.BufferInfo()

                        var done = false
                        while (!done) {
                            bufferInfo.offset = 0
                            bufferInfo.size = extractor.readSampleData(buffer, 0)
                            val sampleTime = extractor.sampleTime

                            if (bufferInfo.size < 0 || sampleTime > endUs) {
                                done = true
                            } else {
                                if (sampleTime >= startUs) {
                                    bufferInfo.presentationTimeUs = sampleTime - startUs
                                    val flags = extractor.sampleFlags
                                    bufferInfo.flags = if (flags and android.media.MediaExtractor.SAMPLE_FLAG_SYNC != 0) {
                                        android.media.MediaCodec.BUFFER_FLAG_KEY_FRAME
                                    } else {
                                        0
                                    }
                                    muxer.writeSampleData(muxerTrackIndex, buffer, bufferInfo)
                                }
                                extractor.advance()
                            }
                        }

                        muxer.stop()
                        muxer.release()
                        extractor.release()
                        trimmedSuccessfully = tempOutFile.exists() && tempOutFile.length() > 0
                    }
                } catch (trimError: Exception) {
                    Timber.tag(TAG).w(trimError, "Native MediaMuxer trimming failed, falling back")
                }

                val finalFile = if (trimmedSuccessfully) tempOutFile else tempFile
                val relativePath = Environment.DIRECTORY_MUSIC + "/Metrolist"

                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    val resolver = appContext.contentResolver
                    val contentValues = ContentValues().apply {
                        put(MediaStore.MediaColumns.DISPLAY_NAME, fileName)
                        put(MediaStore.MediaColumns.MIME_TYPE, "audio/mp4")
                        put(MediaStore.MediaColumns.RELATIVE_PATH, relativePath)
                        put(MediaStore.MediaColumns.IS_PENDING, 1)
                    }

                    val collection = MediaStore.Audio.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
                    val destUri = resolver.insert(collection, contentValues)
                        ?: throw IllegalStateException("Failed to create destination in MediaStore")

                    resolver.openOutputStream(destUri)?.use { out ->
                        finalFile.inputStream().use { input -> input.copyTo(out) }
                    }

                    val complete = ContentValues().apply { put(MediaStore.MediaColumns.IS_PENDING, 0) }
                    resolver.update(destUri, complete, null, null)
                } else {
                    val musicDir = File(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_MUSIC), "Metrolist")
                    if (!musicDir.exists()) {
                        musicDir.mkdirs()
                    }
                    val targetFile = File(musicDir, fileName)
                    finalFile.copyTo(targetFile, overwrite = true)
                }

                tempFile.delete()
                tempOutFile.delete()

                notifBuilder
                    .setContentText(appContext.getString(R.string.exported_to_storage))
                    .setProgress(0, 0, false)
                    .setOngoing(false)
                safeNotify(notificationManager, notifId, notifBuilder.build())

                withContext(Dispatchers.Main) {
                    Toast.makeText(appContext, R.string.exported_to_storage, Toast.LENGTH_LONG).show()
                }
            } catch (e: Exception) {
                Timber.tag(TAG).e(e, "Failed to export trimmed audio file")
                try {
                    notificationManager.cancel(notifId)
                } catch (_: Exception) {}
                withContext(Dispatchers.Main) {
                    Toast.makeText(appContext, R.string.export_audio_failed, Toast.LENGTH_SHORT).show()
                }
            }
        }
    }
}
