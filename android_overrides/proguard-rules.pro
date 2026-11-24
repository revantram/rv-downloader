# Optimization and shrinkage
-dontobfuscate
-optimizationpasses 5
-allowaccessmodification

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

# Ignore warnings from dynamic dependencies
-dontwarn com.yausername.**
-dontwarn io.github.junkfood02.**
-dontwarn okio.**
-dontwarn org.bouncycastle.**
-dontwarn com.fasterxml.jackson.**
-dontwarn org.apache.commons.compress.**
