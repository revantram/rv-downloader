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

                            var infoTitle = "Online Media"
                            var infoThumbnail = ""
                            var infoUploader = ""
                            var infoDuration = 0
                            val formatsList = mutableListOf<Map<String, Any?>>()

                            try {
                                val request = YoutubeDLRequest(url)
                                request.addOption("--ignore-no-formats-error")
                                request.addOption("--no-check-certificates")
                                request.addOption("--no-warnings")
                                request.addOption("--extractor-args", "instagram:app_id=ios")

                                val info: VideoInfo? = try {
                                    YoutubeDL.getInstance().getInfo(request)
                                } catch (e: Throwable) {
                                    Log.w("RVDownloader", "getInfo warning: ${e.message}")
                                    null
                                }

                                if (info != null) {
                                    infoTitle = info.title ?: infoTitle
                                    infoThumbnail = info.thumbnail ?: ""
                                    infoUploader = info.uploader ?: ""
                                    infoDuration = info.duration ?: 0

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
                                }
                            } catch (e: Throwable) {
                                Log.w("RVDownloader", "fetchInfo error: ${e.message}")
                            }

                            if (infoTitle == "Online Media" || infoTitle.isBlank()) {
                                infoTitle = when {
                                    url.contains("instagram.com") -> "Instagram Media"
                                    url.contains("youtube.com") || url.contains("youtu.be") -> "YouTube Video"
                                    url.contains("terabox") || url.contains("1024tera") -> "TeraBox Media"
                                    url.contains("tiktok.com") -> "TikTok Video"
                                    url.contains("facebook.com") || url.contains("fb.watch") -> "Facebook Video"
                                    url.contains("twitter.com") || url.contains("x.com") -> "X / Twitter Video"
                                    else -> "Online Media"
                                }
                            }

                            if (formatsList.isEmpty()) {
                                formatsList.addAll(listOf(
                                    mapOf("formatId" to "1080p", "formatNote" to "1080p (Full HD)", "ext" to "mp4", "height" to 1080, "width" to 1920),
                                    mapOf("formatId" to "720p", "formatNote" to "720p (HD)", "ext" to "mp4", "height" to 720, "width" to 1280),
                                    mapOf("formatId" to "480p", "formatNote" to "480p (SD)", "ext" to "mp4", "height" to 480, "width" to 854),
                                    mapOf("formatId" to "360p", "formatNote" to "360p (Low)", "ext" to "mp4", "height" to 360, "width" to 640)
                                ))
                            }

                            val resultMap = mapOf(
                                "id" to "media_${System.currentTimeMillis()}",
                                "title" to infoTitle,
                                "duration" to infoDuration,
                                "thumbnail" to infoThumbnail,
                                "uploader" to (if (infoUploader.isNotBlank()) infoUploader else infoTitle),
                                "webpageUrl" to url,
                                "description" to "",
                                "formats" to formatsList
                            )

                            withContext(Dispatchers.Main) {
                                result.success(resultMap)
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
                            val startTime = System.currentTimeMillis()
                            val outDir = File(targetDir)
                            try {
                                if (!outDir.exists()) {
                                    outDir.mkdirs()
                                }

                                val request = YoutubeDLRequest(url)
                                request.addOption("--no-mtime")
                                request.addOption("-i")
                                request.addOption("--ignore-no-formats-error")
                                request.addOption("--no-check-certificates")
                                request.addOption("--no-warnings")
                                request.addOption("--extractor-args", "instagram:app_id=ios")

                                val outputTemplate = if (!customTitle.isNullOrBlank() && 
                                    !customTitle.contains("Downloading media", ignoreCase = true) && 
                                    !customTitle.contains("Online Media", ignoreCase = true)) {
                                    val safeName = customTitle.replace(Regex("[\\\\/:*?\"<>|]"), "_")
                                    "${outDir.absolutePath}/$safeName-%(id)s.%(ext)s"
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

                                val recentFiles = scanRecentFiles(outDir, startTime)
                                for (f in recentFiles) {
                                    scanMediaFile(f.absolutePath)
                                }
                                val downloadedFile = recentFiles.maxByOrNull { it.lastModified() } ?: scanAndFindNewestFile(outDir)

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

                                if (isCancelled) {
                                    sendProgressEvent(mapOf(
                                        "taskId" to taskId,
                                        "status" to "cancelled",
                                        "error" to "Download cancelled",
                                        "line" to "Download cancelled"
                                    ))
                                    return@launch
                                }

                                // Check if media files were actually downloaded during this task
                                val recentFiles = scanRecentFiles(outDir, startTime)
                                for (f in recentFiles) {
                                    scanMediaFile(f.absolutePath)
                                }
                                val downloadedFile = recentFiles.maxByOrNull { it.lastModified() }

                                if (downloadedFile != null && downloadedFile.exists() && downloadedFile.length() > 1024) {
                                    Log.i("RVDownloader", "File downloaded successfully despite yt-dlp exit status: ${downloadedFile.absolutePath} (${downloadedFile.length()} bytes)")
                                    sendProgressEvent(mapOf(
                                        "taskId" to taskId,
                                        "status" to "completed",
                                        "progress" to 100.0,
                                        "filePath" to downloadedFile.absolutePath,
                                        "line" to "Download finished successfully"
                                    ))
                                    return@launch
                                }

                                val errorMsg = e.message ?: e.localizedMessage ?: "Download failed: Unknown error"
                                Log.e("RVDownloader", "startDownload failed: $errorMsg", e)

                                var userFriendlyError = errorMsg
                                if (errorMsg.contains("Unsupported URL", ignoreCase = true) && (url.contains("terabox") || url.contains("1024tera"))) {
                                    userFriendlyError = "TeraBox verification required. Tap 'Open in Browser' to view or download directly."
                                } else if (errorMsg.contains("Unsupported URL", ignoreCase = true)) {
                                    userFriendlyError = "Unsupported URL: Please check the link or open directly in browser."
                                } else if (errorMsg.contains("older than 90 days", ignoreCase = true) || errorMsg.contains("extractor", ignoreCase = true)) {
                                    userFriendlyError = "yt-dlp extractor is outdated. Tap 'Update yt-dlp Extractor' in Settings."
                                    try {
                                        YoutubeDL.getInstance().updateYoutubeDL(applicationContext, YoutubeDL.UpdateChannel.STABLE)
                                    } catch (_: Throwable) {}
                                } else if (errorMsg.contains("empty media response", ignoreCase = true)) {
                                    userFriendlyError = "Instagram blocked anonymous access or requires an active session."
                                }

                                sendProgressEvent(mapOf(
                                    "taskId" to taskId,
                                    "status" to "failed",
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

                    "openUrl" -> {
                        val url = call.argument<String>("url")
                        if (!url.isNullOrBlank()) {
                            try {
                                val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url)).apply {
                                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                }
                                startActivity(intent)
                                result.success(true)
                            } catch (e: Throwable) {
                                Log.e("RVDownloader", "Failed to open URL: ${e.message}")
                                result.success(false)
                            }
                        } else {
                            result.error("INVALID_URL", "URL is empty", null)
                        }
                    }

                    "installApk" -> {
                        val path = call.argument<String>("path")
                        if (!path.isNullOrBlank()) {
                            val success = installApkFile(path)
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

    private fun scanRecentFiles(dir: File, minModifiedTime: Long = 0L): List<File> {
        return try {
            dir.listFiles()
                ?.filter {
                    it.isFile &&
                    it.length() > 1024 &&
                    (minModifiedTime == 0L || it.lastModified() >= (minModifiedTime - 15000L)) &&
                    (it.name.endsWith(".mp4", ignoreCase = true) ||
                     it.name.endsWith(".mp3", ignoreCase = true) ||
                     it.name.endsWith(".mkv", ignoreCase = true) ||
                     it.name.endsWith(".webm", ignoreCase = true) ||
                     it.name.endsWith(".m4a", ignoreCase = true))
                } ?: emptyList()
        } catch (_: Throwable) {
            emptyList()
        }
    }

    private fun scanAndFindNewestFile(dir: File, minModifiedTime: Long = 0L): File? {
        val files = scanRecentFiles(dir, minModifiedTime)
        if (files.isNotEmpty()) {
            return files.maxByOrNull { it.lastModified() }
        }
        return try {
            dir.listFiles()
                ?.filter { 
                    it.isFile && 
                    it.length() > 1024 &&
                    (it.name.endsWith(".mp4", ignoreCase = true) ||
                     it.name.endsWith(".mp3", ignoreCase = true) ||
                     it.name.endsWith(".mkv", ignoreCase = true) ||
                     it.name.endsWith(".webm", ignoreCase = true) ||
                     it.name.endsWith(".m4a", ignoreCase = true)) 
                }
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

    private fun installApkFile(filePath: String): Boolean {
        return try {
            val file = File(filePath)
            if (!file.exists()) return false

            val uri = FileProvider.getUriForFile(
                this,
                "${applicationContext.packageName}.fileprovider",
                file
            )

            val intent = Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(uri, "application/vnd.android.package-archive")
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            startActivity(intent)
            true
        } catch (e: Throwable) {
            Log.e("RVDownloader", "Failed to install APK: ${e.message}")
            false
        }
    }
}
