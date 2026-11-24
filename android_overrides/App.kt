package com.rvbhati.rvdownloader

import android.util.Log
import io.flutter.app.FlutterApplication
import com.yausername.youtubedl_android.YoutubeDL

class App : FlutterApplication() {

    companion object {
        @Volatile
        var isYtDlpReady: Boolean = false

        @Volatile
        var initErrorMessage: String? = null
    }

    override fun onCreate() {
        super.onCreate()
        initEngines()
    }

    fun initEngines() {
        try {
            YoutubeDL.getInstance().init(this)
            isYtDlpReady = true
            Log.d("RVDownloader", "YoutubeDL core engine initialized successfully in App.onCreate")
        } catch (e: Throwable) {
            initErrorMessage = e.localizedMessage ?: e.message
            Log.e("RVDownloader", "Failed to initialize YoutubeDL: ${e.message}", e)
        }
    }
}
