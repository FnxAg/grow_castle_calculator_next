import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    // id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keyProperties = Properties()
val keyPropertiesFile = rootProject.file("key.properties")
if (keyPropertiesFile.exists()) {
    keyProperties.load(FileInputStream(keyPropertiesFile))
}

// 自动递增 versionCode：使用 git 提交总数（每次提交单调递增，无需手动改 pubspec.yaml）。
// 非 git 环境（如导出源码构建）回退到 pubspec.yaml 中定义的构建号。
fun gitCommitCount(): Int? {
    return try {
        ProcessBuilder("git", "rev-list", "--count", "HEAD")
            .redirectErrorStream(true)
            .start()
            .inputStream.bufferedReader().readText().trim()
            .toIntOrNull()
            ?.takeIf { it > 0 }
    } catch (e: Exception) {
        null
    }
}

val versionCodeFromGit: Int? = gitCommitCount()

android {
    namespace = "com.example.grow_castle_calculator_next"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "fnxag.gccnext"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = versionCodeFromGit ?: flutter.versionCode
        versionName = flutter.versionName
        // ndk {
        //     abiFilters += listOf("arm64-v8a")
        // }
    }

    buildTypes {
        debug {
            signingConfig = signingConfigs.getByName("debug")
            isDebuggable = true
            // 调试包使用独立包名，可与 release 包共存安装
            applicationIdSuffix = ".debug"
        }
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            isMinifyEnabled = true
            isShrinkResources = true

            if (keyProperties.containsKey("storeFile")) {
                signingConfig = signingConfigs.create("release") {
                    storeFile = file(keyProperties["storeFile"] as String)
                    storePassword = keyProperties["storePassword"] as String
                    keyAlias = keyProperties["keyAlias"] as String
                    keyPassword = keyProperties["keyPassword"] as String
                }
            } else {
                signingConfig = signingConfigs.getByName("debug")
            }
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
