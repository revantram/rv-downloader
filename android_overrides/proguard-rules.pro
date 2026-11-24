# Optimization and shrinkage controls
-dontobfuscate
-dontoptimize
-dontshrink

# Keep Apache Commons Compress classes and constructors completely
-keep class org.apache.commons.compress.** { *; }
-keep interface org.apache.commons.compress.** { *; }
-keepclassmembers class org.apache.commons.compress.** { *; }
-keepclassmembernames class org.apache.commons.compress.** { *; }
-keep class org.apache.commons.compress.archivers.zip.** { *; }

# Keep YoutubeDL and yt-dlp native bindings & reflection models
-keep class com.yausername.** { *; }
-keep interface com.yausername.** { *; }
-keep class io.github.junkfood02.** { *; }
-keep interface io.github.junkfood02.** { *; }

# Keep VideoInfo & formats models used by getInfo()
-keep class com.yausername.youtubedl_android.mapper.** { *; }
-keep class io.github.junkfood02.youtubedl_android.mapper.** { *; }

# Keep App and MainActivity
-keep class com.rvbhati.rvdownloader.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Prevent native methods and Python bridge structures from stripping
-keepclasseswithmembernames class * {
    native <methods>;
}

# Ignore warnings from all dynamic dependencies and missing play-core classes
-dontwarn **
