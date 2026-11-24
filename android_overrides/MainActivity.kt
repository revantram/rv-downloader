package com.rvbhati.rvdownloader

import android.content.Context
import android.content.Intent
import android.media.MediaScannerConnection
import android.net.Uri
import android.os.Bundle
import android.os.Environment
import android.util.Log
import android.webkit.MimeTypeMap
import androidx.annotation.NonNull
import androidx.core.content.FileProvider
import com.yausername.youtubedl_android.YoutubeDL
import com.yausername.youtubedl_android.YoutubeDLException
import com.yausername.youtubedl_android.YoutubeDLRequest
import com.yausername.youtubedl_android.mapper.VideoInfo
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.io.File
import java.util.concurrent.ConcurrentHashMap

class MainActivity : FlutterActivity() {

    private val CHANNEL_NAME = "com.rvbhati.rvdownloader/engine"
    private val PROGRESS_EVENT_CHANNEL = "com.rvbhati.rvdownloader/progress_events"

    private val activityScope = CoroutineScope(SupervisorJob() + Dispatchers.Main)
    private var pendingSharedText: String? = null

    private var eventSink: EventChannel.EventSink? = null
    private val activeTasks = ConcurrentHashMap<String, Boolean>()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleIntent(intent)
        ensureEngineReady(applicationContext)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent?) {
        if (intent == null) return
        val action = intent.action
        val type = intent.type
        if (Intent.ACTION_SEND == action && type != null && "text/plain" == type) {
            val sharedText = intent.getStringExtra(Intent.EXTRA_TEXT)
            if (!sharedText.isNullOrBlank()) {
                pendingSharedText = sharedText
            }
        }
    }

    @Synchronized
    private fun ensureEngineReady(context: Context) {
        if (!App.isYtDlpReady) {
            try {
                YoutubeDL.getInstance().init(context.applicationContext)
                App.isYtDlpReady = true
                Log.d("RVDownloader", "YoutubeDL initialized via ensureEngineReady")
            } catch (e: Throwable) {
                App.initErrorMessage = e.message ?: e.localizedMessage
                Log.e("RVDownloader", "Failed to init YoutubeDL in ensureEngineReady: ${e.message}", e)
            }
        }
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // EventChannel for real-time progress callbacks
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, PROGRESS_EVENT_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                }

                override fun onCancel(arguments: Any?) {
                    eventSink = null
                }
            })

        // MethodChannel for commands
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_NAME)
            .setMethodCallHandler { call: MethodCall, result: MethodChannel.Result ->
                when (call.method) {
                    "initEngine" -> {
                        activityScope.launch(Dispatchers.IO) {
                            ensureEngineReady(applicationContext)
                            if (App.isYtDlpReady) {
                                val ver = try {
                                    YoutubeDL.getInstance().version(applicationContext) ?: "yt-dlp Core"
                                } catch (_: Throwable) {
                                    "yt-dlp Core"
                                }
                                withContext(Dispatchers.Main) {
                                    result.success(mapOf("success" to true, "version" to ver))
                                }
                            } else {
                                withContext(Dispatchers.Main) {
                                    result.error("INIT_ERROR", App.initErrorMessage ?: "Failed to initialize yt-dlp native environment", null)
                                }
                            }
                        }
                    }

                    "getEngineVersion" -> {
                        activityScope.launch(Dispatchers.IO) {
                            ensureEngineReady(applicationContext)
                            try {
                                val ver = YoutubeDL.getInstance().version(applicationContext) ?: "yt-dlp Embedded"
                                withContext(Dispatchers.Main) {
                                    result.success(ver)
                                }
                            } catch (e: Throwable) {
                                withContext(Dispatchers.Main) {
                                    result.success("yt-dlp Embedded")
                                }
                            }
                        }
                    }

                    "updateEngine" -> {
                        activityScope.launch(Dispatchers.IO) {
                            ensureEngineReady(applicationContext)
                            if (!App.isYtDlpReady) {
                                withContext(Dispatchers.Main) {
                                    result.error("UPDATE_FAILED", App.initErrorMessage ?: "Engine not initialized", null)
                                }
                                return@launch
                            }
                            try {
                                val updateStatus = YoutubeDL.getInstance().updateYoutubeDL(
                                    applicationContext,
                                    YoutubeDL.UpdateChannel.STABLE
                                )
                                val newVer = YoutubeDL.getInstance().version(applicationContext) ?: ""
                                withContext(Dispatchers.Main) {
                                    result.success(
                                        mapOf(
                                            "status" to (updateStatus?.name ?: "DONE"),
                                            "version" to newVer
                                        )
                                    )
                                }
                            } catch (e: Throwable) {
                                val errorMsg = e.message ?: e.localizedMessage ?: "Failed to update yt-dlp: Network timeout or rate limit"
                                Log.e("RVDownloader", "updateEngine error: $errorMsg", e)
                                withContext(Dispatchers.Main) {
                                    result.error("UPDATE_FAILED", errorMsg, Log.getStackTraceString(e))
                                }
                            }
                        }
                    }

                    "getPendingSharedText" -> {
                        val text = pendingSharedText
                        pendingSharedText = null
                        result.success(text)
                    }

                    "fetchInfo" -> {
                        val url = call.argument<String>("url")
                        if (url.isNullOrBlank()) {
                            result.error("INVALID_URL", "URL cannot be empty", null)
                            return@setMethodCallHandler
                        }

                        activityScope.launch(Dispatchers.IO) {
                            ensureEngineReady(applicationContext)
                            if (!App.isYtDlpReady) {
                                withContext(Dispatchers.Main) {
                                    result.error("FETCH_INFO_ERROR", App.initErrorMessage ?: "yt-dlp engine is not initialized yet. Please restart the app.", null)
                                }
                                return@launch
                            }
                            try {
                                val request = YoutubeDLRequest(url)
                                request.addOption("--no-playlist")
                                request.addOption("--no-check-certificates")
                                request.addOption("--no-warnings")
                                request.addOption("--extractor-args", "instagram:app_id=ios")
                                
                                val info: VideoInfo = YoutubeDL.getInstance().getInfo(request)
                                val formatsList = mutableListOf<Map<String, Any?>>()

                                info.formats?.forEach { f ->
                                    val fMap = mapOf(
                                        "formatId" to (f.formatId ?: ""),
                                        "formatNote" to (f.formatNote ?: ""),
                                        "ext" to (f.ext ?: ""),
                                        "vcodec" to (f.vcodec ?: ""),
                                        "acodec" to (f.acodec ?: ""),
                                        "filesize" to (f.fileSize ?: 0L),
                                        "fps" to (f.fps ?: 0),
                                        "height" to (f.height ?: 0),
                                        "width" to (f.width ?: 0),
                                        "tbr" to (f.tbr ?: 0)
                                    )
                                    formatsList.add(fMap)
                                }

                                val resultMap = mapOf(
                                    "id" to (info.id ?: ""),
                                    "title" to (info.title ?: "Untitled Media"),
                                    "duration" to (info.duration ?: 0),
                                    "thumbnail" to (info.thumbnail ?: ""),
                                    "uploader" to (info.uploader ?: ""),
                                    "webpageUrl" to (info.webpageUrl ?: url),
                                    "description" to (info.description ?: ""),
                                    "formats" to formatsList
                                )

                                withContext(Dispatchers.Main) {
                                    result.success(resultMap)
                                }
                            } catch (e: Throwable) {
                                val errorMsg = e.message ?: e.localizedMessage ?: "Failed to fetch media info from URL"
                                Log.e("RVDownloader", "fetchInfo error: $errorMsg", e)
                                withContext(Dispatchers.Main) {
                                    result.error("FETCH_INFO_ERROR", errorMsg, Log.getStackTraceString(e))
                                }
                            }
                        }
                    }

                    "startDownload" -> {
                        val taskId = call.argument<String>("taskId") ?: System.currentTimeMillis().toString()
                        val url = call.argument<String>("url") ?: ""
                        val quality = call.argument<String>("quality") ?: "best"
                        val isAudioOnly = call.argument<Boolean>("isAudioOnly") ?: false
                        val customTitle = call.argument<String>("customTitle")
                        val targetDir = call.argument<String>("targetDir") ?: getPublicDownloadDir()

                        if (url.isBlank()) {
                            result.error("INVALID_URL", "Target URL is required", null)
                            return@setMethodCallHandler
                        }

                        activeTasks[taskId] = true
                        result.success(taskId)

                        activityScope.launch(Dispatchers.IO) {
                            ensureEngineReady(applicationContext)
                            if (!App.isYtDlpReady) {
                                activeTasks.remove(taskId)
                                val msg = App.initErrorMessage ?: "yt-dlp engine is not ready. Please restart the app."
                                sendProgressEvent(mapOf(
                                    "taskId" to taskId,
                                    "status" to "failed",
                                    "error" to msg,
                                    "line" to msg
                                ))
                                return@launch
                            }
                            try {
                                val outDir = File(targetDir)
                                if (!outDir.exists()) {
                                    outDir.mkdirs()
                                }

                                val request = YoutubeDLRequest(url)
                                request.addOption("--no-mtime")
                                request.addOption("--no-playlist")
                                request.addOption("--no-check-certificates")
                                request.addOption("--no-warnings")
                                request.addOption("--extractor-args", "instagram:app_id=ios")

                                val outputTemplate = if (!customTitle.isNullOrBlank()) {
                                    val safeName = customTitle.replace(Regex("[\\\\/:*?\"<>|]"), "_")
                                    "${outDir.absolutePath}/$safeName.%(ext)s"
                                } else {
                                    "${outDir.absolutePath}/%(title).100s-%(id)s.%(ext)s"
                                }
                                request.addOption("-o", outputTemplate)

                                if (isAudioOnly) {
                                    // Direct native high quality audio stream (m4a, mp3, aac, opus)
                                    request.addOption("-f", "bestaudio/best")
                                } else {
                                    // Direct progressive MP4 stream (Instagram, TeraBox, TikTok, YouTube 720p/360p)
                                    when (quality.lowercase()) {
                                        "1080p" -> request.addOption("-f", "best[height<=1080][ext=mp4]/best[height<=1080]/best[ext=mp4]/best")
                                        "720p" -> request.addOption("-f", "best[height<=720][ext=mp4]/best[height<=720]/best[ext=mp4]/best")
                                        "480p" -> request.addOption("-f", "best[height<=480][ext=mp4]/best[height<=480]/best[ext=mp4]/best")
                                        "360p" -> request.addOption("-f", "best[height<=360][ext=mp4]/best[height<=360]/best[ext=mp4]/best")
                                        else -> request.addOption("-f", "best[ext=mp4]/best")
                                    }
                                }

                                sendProgressEvent(mapOf(
                                    "taskId" to taskId,
                                    "status" to "starting",
                                    "progress" to 0.0,
                                    "eta" to 0L,
                                    "line" to "Starting download engine..."
                                ))

                                val response = YoutubeDL.getInstance().execute(request, taskId) { progress, etaInSeconds, line ->
                                    sendProgressEvent(mapOf(
                                        "taskId" to taskId,
                                        "status" to "downloading",
                                        "progress" to progress.toDouble(),
                                        "eta" to etaInSeconds,
                                        "line" to (line ?: "")
                                    ))
                                }

                                activeTasks.remove(taskId)

                                val downloadedFile = scanAndFindNewestFile(outDir)
                                if (downloadedFile != null && downloadedFile.exists()) {
                                    scanMediaFile(downloadedFile.absolutePath)
                                }

                                sendProgressEvent(mapOf(
                                    "taskId" to taskId,
                                    "status" to "completed",
                                    "progress" to 100.0,
                                    "filePath" to (downloadedFile?.absolutePath ?: ""),
                                    "line" to (response.out ?: "Download finished successfully")
                                ))

                            } catch (e: Throwable) {
                                activeTasks.remove(taskId)
                                val isCancelled = e.message?.contains("destroy", ignoreCase = true) == true
                                        || e.message?.contains("cancel", ignoreCase = true) == true
                                        || e.message?.contains("interrupted", ignoreCase = true) == true

                                val errorMsg = e.message ?: e.localizedMessage ?: "Download failed: Unknown error"
                                Log.e("RVDownloader", "startDownload failed: $errorMsg", e)

                                var userFriendlyError = errorMsg
                                if (errorMsg.contains("older than 90 days", ignoreCase = true) || errorMsg.contains("extractor", ignoreCase = true)) {
                                    userFriendlyError = "yt-dlp extractor is outdated. Tap 'Update yt-dlp Extractor' in Settings."
                                    try {
                                        YoutubeDL.getInstance().updateYoutubeDL(applicationContext, YoutubeDL.UpdateChannel.STABLE)
                                    } catch (_: Throwable) {}
                                }

                                sendProgressEvent(mapOf(
                                    "taskId" to taskId,
                                    "status" to if (isCancelled) "cancelled" else "failed",
                                    "error" to userFriendlyError,
                                    "line" to userFriendlyError
                                ))
                            }
                        }
                    }

                    "cancelDownload" -> {
                        val taskId = call.argument<String>("taskId")
                        if (!taskId.isNullOrBlank()) {
                            activityScope.launch(Dispatchers.IO) {
                                try {
                                    YoutubeDL.getInstance().destroyProcessById(taskId)
                                    activeTasks.remove(taskId)
                                    withContext(Dispatchers.Main) {
                                        result.success(true)
                                    }
                                } catch (e: Throwable) {
                                    withContext(Dispatchers.Main) {
                                        result.success(false)
                                    }
                                }
                            }
                        } else {
                            result.success(false)
                        }
                    }

                    "scanMedia" -> {
                        val path = call.argument<String>("path")
                        if (!path.isNullOrBlank()) {
                            scanMediaFile(path)
                            result.success(true)
                        } else {
                            result.success(false)
                        }
                    }

                    "openFile" -> {
                        val path = call.argument<String>("path")
                        if (!path.isNullOrBlank()) {
                            val success = openMediaFile(path)
                            result.success(success)
                        } else {
                            result.error("INVALID_PATH", "Path is empty", null)
                        }
                    }

                    "shareFile" -> {
                        val path = call.argument<String>("path")
                        if (!path.isNullOrBlank()) {
                            val success = shareMediaFile(path)
                            result.success(success)
                        } else {
                            result.error("INVALID_PATH", "Path is empty", null)
                        }
                    }

                    else -> result.notImplemented()
                }
            }
    }

    private fun sendProgressEvent(data: Map<String, Any?>) {
        activityScope.launch(Dispatchers.Main) {
            try {
                eventSink?.success(data)
            } catch (_: Throwable) {}
        }
    }

    private fun getPublicDownloadDir(): String {
        val publicDir = File(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS), "RV-Downloader")
        if (!publicDir.exists()) {
            publicDir.mkdirs()
        }
        return publicDir.absolutePath
    }

    private fun scanAndFindNewestFile(dir: File): File? {
        return try {
            dir.listFiles()
                ?.filter { it.isFile && (it.name.endsWith(".mp4") || it.name.endsWith(".mp3") || it.name.endsWith(".mkv") || it.name.endsWith(".webm") || it.name.endsWith(".m4a")) }
                ?.maxByOrNull { it.lastModified() }
        } catch (_: Throwable) {
            null
        }
    }

    private fun scanMediaFile(filePath: String) {
        try {
            MediaScannerConnection.scanFile(
                applicationContext,
                arrayOf(filePath),
                null
            ) { path, uri ->
                Log.d("RVDownloader", "Scanned media: $path -> $uri")
            }
        } catch (e: Throwable) {
            Log.e("RVDownloader", "Media scan failed: ${e.message}")
        }
    }

    private fun openMediaFile(filePath: String): Boolean {
        return try {
            val file = File(filePath)
            if (!file.exists()) return false

            val uri = FileProvider.getUriForFile(
                this,
                "${applicationContext.packageName}.fileprovider",
                file
            )

            val ext = MimeTypeMap.getFileExtensionFromUrl(Uri.fromFile(file).toString())
            val mimeType = MimeTypeMap.getSingleton().getMimeTypeFromExtension(ext.lowercase())
                ?: if (filePath.endsWith(".mp3") || filePath.endsWith(".m4a")) "audio/*" else "video/*"

            val intent = Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(uri, mimeType)
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            startActivity(intent)
            true
        } catch (e: Throwable) {
            Log.e("RVDownloader", "Failed to open file: ${e.message}")
            false
        }
    }

    private fun shareMediaFile(filePath: String): Boolean {
        return try {
            val file = File(filePath)
            if (!file.exists()) return false

            val uri = FileProvider.getUriForFile(
                this,
                "${applicationContext.packageName}.fileprovider",
                file
            )

            val ext = MimeTypeMap.getFileExtensionFromUrl(Uri.fromFile(file).toString())
            val mimeType = MimeTypeMap.getSingleton().getMimeTypeFromExtension(ext.lowercase())
                ?: if (filePath.endsWith(".mp3") || filePath.endsWith(".m4a")) "audio/*" else "video/*"

            val intent = Intent(Intent.ACTION_SEND).apply {
                type = mimeType
                putExtra(Intent.EXTRA_STREAM, uri)
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            }
            startActivity(Intent.createChooser(intent, "Share Media"))
            true
        } catch (e: Throwable) {
            Log.e("RVDownloader", "Failed to share file: ${e.message}")
            false
        }
    }
}
