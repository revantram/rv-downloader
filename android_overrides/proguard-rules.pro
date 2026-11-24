# Shrink and optimize
-dontobfuscate
-optimizationpasses 5
-allowaccessmodification

# Keep YoutubeDL and FFmpeg native bindings
-keep class com.yausername.** { *; }
-keep interface com.yausername.** { *; }
-keep class io.github.junkfood02.** { *; }
-keep interface io.github.junkfood02.** { *; }

# Keep MainActivity and Flutter Embedding
-keep class com.rvbhati.rvdownloader.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Ignore warnings from dynamic dependencies
-dontwarn com.yausername.**
-dontwarn io.github.junkfood02.**
-dontwarn okio.**
-dontwarn org.bouncycastle.**
-dontwarn com.fasterxml.jackson.**
