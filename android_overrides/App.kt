package com.rvbhati.rvdownloader

import android.content.Context
import android.util.Log
import androidx.multidex.MultiDex
import io.flutter.app.FlutterApplication
import com.yausername.youtubedl_android.YoutubeDL
import java.io.File

class App : FlutterApplication() {

    companion object {
        @Volatile
        var isYtDlpReady: Boolean = false

        @Volatile
        var initErrorMessage: String? = null
    }

    override fun attachBaseContext(base: Context) {
        super.attachBaseContext(base)
        try {
            MultiDex.install(this)
        } catch (e: Throwable) {
            Log.w("RVDownloader", "MultiDex install warning: ${e.message}")
        }
    }

    override fun onCreate() {
        super.onCreate()
        // Initialize heavy yt-dlp python unarchiving in background thread so app startup never blocks or crashes
        Thread {
            initEngines()
        }.start()
    }

    fun initEngines() {
        try {
            // Clean up stale 2025 binary cache so fresh bundled 2026.11.23 yt-dlp binary is unpacked
            try {
                val ytdlpDir = File(noBackupFilesDir, "youtubedl-android/yt-dlp")
                val prefs = getSharedPreferences("youtubedl-android", Context.MODE_PRIVATE)
                val currentVer = prefs.getString("dlpVersion", "") ?: ""
                if (currentVer.startsWith("2025") || currentVer.isBlank()) {
                    ytdlpDir.deleteRecursively()
                    prefs.edit().remove("dlpVersion").remove("dlpVersionName").apply()
                    Log.d("RVDownloader", "Purged outdated yt-dlp binary cache ($currentVer) for fresh 2026 extractor")
                }
            } catch (e: Throwable) {
                Log.w("RVDownloader", "yt-dlp cache purge check warning: ${e.message}")
            }

            YoutubeDL.getInstance().init(this)
            isYtDlpReady = true
            Log.d("RVDownloader", "YoutubeDL core engine initialized successfully")
        } catch (e: Throwable) {
            initErrorMessage = e.localizedMessage ?: e.message
            Log.e("RVDownloader", "Failed to initialize YoutubeDL: ${e.message}", e)
        }
    }
}
