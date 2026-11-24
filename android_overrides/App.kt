package com.rvbhati.rvdownloader

import android.content.Context
import android.util.Log
import androidx.multidex.MultiDex
import io.flutter.app.FlutterApplication
import com.yausername.youtubedl_android.YoutubeDL

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
            YoutubeDL.getInstance().init(this)
            isYtDlpReady = true
            Log.d("RVDownloader", "YoutubeDL core engine initialized successfully")
        } catch (e: Throwable) {
            initErrorMessage = e.localizedMessage ?: e.message
            Log.e("RVDownloader", "Failed to initialize YoutubeDL: ${e.message}", e)
        }
    }
}
