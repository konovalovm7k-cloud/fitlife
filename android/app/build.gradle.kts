plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val releaseStore = System.getenv("FITLIFE_KEYSTORE_PATH")

android {
    namespace = "com.example.fitlife"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // Preserve the identifier used by existing FitLife APKs.
        applicationId = "com.example.fitlife"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (!releaseStore.isNullOrBlank()) {
            create("fitlifeRelease") {
                storeFile = file(releaseStore)
                storePassword = requireNotNull(System.getenv("FITLIFE_STORE_PASSWORD")?.takeIf { it.isNotBlank() }) {
                    "FITLIFE_STORE_PASSWORD is required when FITLIFE_KEYSTORE_PATH is set"
                }
                keyAlias = System.getenv("FITLIFE_KEY_ALIAS")?.takeIf { it.isNotBlank() } ?: "fitlife"
                keyPassword = System.getenv("FITLIFE_KEY_PASSWORD")?.takeIf { it.isNotBlank() } ?: storePassword
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName(
                if (releaseStore.isNullOrBlank()) "debug" else "fitlifeRelease"
            )
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
