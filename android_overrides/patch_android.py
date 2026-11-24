import os
import re

def patch_app_gradle():
    kts_path = "android/app/build.gradle.kts"
    groovy_path = "android/app/build.gradle"

    if os.path.exists(kts_path):
        print(f"Patching {kts_path}...")
        with open(kts_path, "r", encoding="utf-8") as f:
            content = f.read()

        # Update minSdk to 24
        content = re.sub(r'minSdk\s*=\s*flutter\.minSdkVersion', 'minSdk = 24', content)
        content = re.sub(r'minSdk\s*=\s*\d+', 'minSdk = 24', content)

        # Restrict NDK to arm64-v8a only
        ndk_filter = """
        ndk {
            abiFilters.clear()
            abiFilters.add("arm64-v8a")
        }
"""
        if "abiFilters.add(\"arm64-v8a\")" not in content:
            if "defaultConfig {" in content:
                content = content.replace("defaultConfig {", "defaultConfig {" + ndk_filter)

        # Release signing and R8 minification/shrinking
        signing_block = """
    signingConfigs {
        create("release") {
            storeFile = file("release.jks")
            storePassword = "rvbhati123"
            keyAlias = "rvbhati"
            keyPassword = "rvbhati123"
        }
    }
    lint {
        checkReleaseBuilds = false
        abortOnError = false
    }
    packaging {
        resources {
            excludes += "/META-INF/{AL2.0,LGPL2.1}"
            excludes += "DebugProbesKt.bin"
            excludes += "/META-INF/*.version"
        }
        jniLibs {
            useLegacyPackaging = true
        }
    }
"""
        if 'create("release")' not in content:
            content = content.replace("buildTypes {", signing_block + "\n    buildTypes {")

        # Configure release build type with R8 shrinking
        content = content.replace(
            'signingConfigs.getByName("debug")',
            'signingConfigs.getByName("release")\n            isMinifyEnabled = true\n            isShrinkResources = true\n            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")'
        )

        # Dependencies
        dep_block = """
dependencies {
    implementation("io.github.junkfood02.youtubedl-android:library:0.18.1")
    implementation("io.github.junkfood02.youtubedl-android:ffmpeg:0.18.1")
    implementation("androidx.core:core-ktx:1.12.0")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.7.3")
"""
        if "youtubedl-android" not in content:
            if "dependencies {" in content:
                content = content.replace("dependencies {", dep_block)
            else:
                content += "\n" + dep_block + "\n}\n"

        with open(kts_path, "w", encoding="utf-8") as f:
            f.write(content)
        print("Successfully patched build.gradle.kts with R8 shrinking & ARM64 optimization")

    elif os.path.exists(groovy_path):
        print(f"Patching {groovy_path}...")
        with open(groovy_path, "r", encoding="utf-8") as f:
            content = f.read()

        # Update minSdk
        content = re.sub(r'minSdkVersion\s+flutter\.minSdkVersion', 'minSdkVersion 24', content)
        content = re.sub(r'minSdkVersion\s+\d+', 'minSdkVersion 24', content)

        # Restrict NDK
        ndk_filter = """
        ndk {
            abiFilters 'arm64-v8a'
        }
"""
        if "'arm64-v8a'" not in content:
            if "defaultConfig {" in content:
                content = content.replace("defaultConfig {", "defaultConfig {" + ndk_filter)

        signing_block = """
    signingConfigs {
        release {
            storeFile file("release.jks")
            storePassword "rvbhati123"
            keyAlias "rvbhati"
            keyPassword "rvbhati123"
        }
    }
    lintOptions {
        checkReleaseBuilds false
        abortOnError false
    }
    packagingOptions {
        resources {
            excludes += ['META-INF/AL2.0', 'META-INF/LGPL2.1', 'DebugProbesKt.bin']
        }
    }
"""
        if "signingConfigs {" not in content or "release {" not in content:
            content = content.replace("buildTypes {", signing_block + "\n    buildTypes {")

        content = content.replace(
            "signingConfigs.debug",
            "signingConfigs.release\n            minifyEnabled true\n            shrinkResources true\n            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'"
        )

        dep_block = """
dependencies {
    implementation 'io.github.junkfood02.youtubedl-android:library:0.18.1'
    implementation 'io.github.junkfood02.youtubedl-android:ffmpeg:0.18.1'
    implementation 'androidx.core:core-ktx:1.12.0'
    implementation 'org.jetbrains.kotlinx:kotlinx-coroutines-android:1.7.3'
"""
        if "youtubedl-android" not in content:
            if "dependencies {" in content:
                content = content.replace("dependencies {", dep_block)
            else:
                content += "\n" + dep_block + "\n}\n"

        with open(groovy_path, "w", encoding="utf-8") as f:
            f.write(content)
        print("Successfully patched build.gradle with R8 shrinking & ARM64 optimization")

def patch_root_repositories():
    settings_gradle = "android/settings.gradle"
    settings_kts = "android/settings.gradle.kts"
    root_gradle = "android/build.gradle"
    root_kts = "android/build.gradle.kts"

    for file_path in [settings_gradle, settings_kts, root_gradle, root_kts]:
        if os.path.exists(file_path):
            with open(file_path, "r", encoding="utf-8") as f:
                c = f.read()
            if "mavenCentral()" not in c and "mavenCentral" not in c:
                c = c.replace("google()", "google()\n        mavenCentral()")
            with open(file_path, "w", encoding="utf-8") as f:
                f.write(c)
            print(f"Ensured repositories in {file_path}")

if __name__ == "__main__":
    patch_app_gradle()
    patch_root_repositories()
